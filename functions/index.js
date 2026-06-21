const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onValueCreated } = require('firebase-functions/v2/database');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const https = require('https');
const Groq = require('groq-sdk');

admin.initializeApp();

const db = admin.firestore();

// ─────────────────────────────────────────────
// Function 1: New application → notify company
// ─────────────────────────────────────────────
exports.onNewApplication = onDocumentCreated(
  'applications/{applicationId}',
  async (event) => {
    const { applicationId } = event.params;
    const data = event.data.data();

    if (!data) {
      logger.warn(`No data for application ${applicationId}`);
      return;
    }

    const companyId = data.companyId;
    const applicantName = data.seekerName || 'Someone';
    const jobTitle = data.jobTitle || 'a position';

    if (!companyId) {
      logger.warn(`No companyId on application ${applicationId}`);
      return;
    }

    const jobId = data.jobId;
    if (jobId) {
      const jobDoc = await db.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) {
        logger.warn(`Job ${jobId} no longer exists, skipping notification`);
        return;
      }
    }

    // Write notification to Firestore unconditionally (in-app badge/list)
    try {
      await db
        .collection('notifications').doc(companyId).collection('items')
        .add({
          type: 'new_application',
          title: 'New Application Received 📋',
          body: `${applicantName} applied for ${jobTitle}`,
          applicationId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      logger.info(`Notification document written for company ${companyId}`);
    } catch (err) {
      logger.error('Failed to write notification document', err);
    }

    // FCM push is best-effort — do not gate anything on it
    let fcmToken;
    try {
      const companyDoc = await db.collection('companies').doc(companyId).get();
      fcmToken = companyDoc.data()?.fcmToken;
    } catch (err) {
      logger.error(`Failed to read company doc for ${companyId}`, err);
      return;
    }

    if (!fcmToken) {
      logger.warn(`No FCM token for company ${companyId}`);
      return;
    }
    logger.info(`FCM token found for company ${companyId} (len=${fcmToken.length})`);

    const message = {
      data: {
        type: 'new_application',
        title: 'New Application Received 📋',
        body: `${applicantName} applied for ${jobTitle}`,
        applicationId,
      },
      token: fcmToken,
    };

    logger.info(`onNewApplication: FCM token for company ${companyId}: "${fcmToken}" (len=${fcmToken.length})`);
    try {
      const response = await admin.messaging().send(message);
      logger.info(`onNewApplication: FCM send SUCCESS to company ${companyId}, response: ${JSON.stringify(response)}`);
    } catch (err) {
      logger.error(`onNewApplication: FCM send FAILED for company ${companyId}: ${err.message} (code=${err.code})`);
    }
  },
);

// ─────────────────────────────────────────────
// Function 2: Application accepted → notify seeker
// ─────────────────────────────────────────────
exports.onApplicationAccepted = onDocumentUpdated(
  'applications/{applicationId}',
  async (event) => {
    const { applicationId } = event.params;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!after) return;
    if (after.status !== 'Accepted') return;
    if (before && before.status === 'Accepted') return;

    const jobSeekerId = after.seekerId || after.jobSeekerId;
    const jobTitle = after.jobTitle || 'a position';

    if (!jobSeekerId) {
      logger.warn(`No jobSeekerId on application ${applicationId}`);
      return;
    }

    // Write notification to Firestore unconditionally
    try {
      await db
        .collection('notifications').doc(jobSeekerId).collection('items')
        .add({
          type: 'application_update',
          title: 'Application Accepted! 🎉',
          body: `Your application for ${jobTitle} has been accepted`,
          applicationId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      logger.info(`Notification document written for job seeker ${jobSeekerId}`);
    } catch (err) {
      logger.error('Failed to write notification document', err);
    }

    // FCM push is best-effort
    let fcmToken;
    try {
      const seekerDoc = await db.collection('jobSeekers').doc(jobSeekerId).get();
      fcmToken = seekerDoc.data()?.fcmToken;
    } catch (err) {
      logger.error(`Failed to read jobSeeker doc for ${jobSeekerId}`, err);
      return;
    }

    if (!fcmToken) {
      logger.warn(`No FCM token for job seeker ${jobSeekerId}`);
      return;
    }

    const message = {
      data: {
        type: 'application_update',
        title: 'Application Accepted! 🎉',
        body: `Congratulations! Your application for ${jobTitle} has been accepted`,
        applicationId,
      },
      token: fcmToken,
    };

    logger.info(`onApplicationAccepted: FCM token for seeker ${jobSeekerId}: "${fcmToken}" (len=${fcmToken.length})`);
    try {
      const response = await admin.messaging().send(message);
      logger.info(`onApplicationAccepted: FCM send SUCCESS to seeker ${jobSeekerId}, response: ${JSON.stringify(response)}`);
    } catch (err) {
      logger.error(`onApplicationAccepted: FCM send FAILED for seeker ${jobSeekerId}: ${err.message} (code=${err.code})`);
    }
  },
);

// ─────────────────────────────────────────────
// Function 3: Application rejected → notify seeker
// ─────────────────────────────────────────────
exports.onApplicationRejected = onDocumentUpdated(
  'applications/{applicationId}',
  async (event) => {
    const { applicationId } = event.params;
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!after) return;
    if (after.status !== 'Rejected') return;
    if (before && before.status === 'Rejected') return;

    const jobSeekerId = after.seekerId || after.jobSeekerId;
    const jobTitle = after.jobTitle || 'a position';

    if (!jobSeekerId) {
      logger.warn(`No jobSeekerId on application ${applicationId}`);
      return;
    }

    // Write notification to Firestore unconditionally
    try {
      await db
        .collection('notifications').doc(jobSeekerId).collection('items')
        .add({
          type: 'application_update',
          title: 'Application Update',
          body: `Unfortunately, your application for ${jobTitle} was not accepted`,
          applicationId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      logger.info(`Notification document written for job seeker ${jobSeekerId}`);
    } catch (err) {
      logger.error('Failed to write notification document', err);
    }

    // FCM push is best-effort
    let fcmToken;
    try {
      const seekerDoc = await db.collection('jobSeekers').doc(jobSeekerId).get();
      fcmToken = seekerDoc.data()?.fcmToken;
    } catch (err) {
      logger.error(`Failed to read jobSeeker doc for ${jobSeekerId}`, err);
      return;
    }

    if (!fcmToken) {
      logger.warn(`No FCM token for job seeker ${jobSeekerId}`);
      return;
    }

    const message = {
      data: {
        type: 'application_update',
        title: 'Application Update',
        body: `Unfortunately, your application for ${jobTitle} was not accepted`,
        applicationId,
      },
      token: fcmToken,
    };

    logger.info(`onApplicationRejected: FCM token for seeker ${jobSeekerId}: "${fcmToken}" (len=${fcmToken.length})`);
    try {
      const response = await admin.messaging().send(message);
      logger.info(`onApplicationRejected: FCM send SUCCESS to seeker ${jobSeekerId}, response: ${JSON.stringify(response)}`);
    } catch (err) {
      logger.error(`onApplicationRejected: FCM send FAILED for seeker ${jobSeekerId}: ${err.message} (code=${err.code})`);
    }
  },
);

// ─────────────────────────────────────────────
// Function 4: New chat message → notify recipient
// ─────────────────────────────────────────────
exports.onNewChatMessage = onValueCreated(
  'chats/{chatId}/messages/{pushId}',
  async (event) => {
    const { chatId } = event.params;
    const data = event.data.val();

    if (!data) return;

    const senderId = data.senderId;
    if (!senderId) return;

    let chatData;
    try {
      const chatSnapshot = await admin
        .database()
        .ref(`chats/${chatId}`)
        .once('value');
      chatData = chatSnapshot.val();
    } catch (err) {
      logger.error(`Failed to read chat ${chatId}`, err);
      return;
    }

    if (!chatData) {
      logger.warn(`Chat ${chatId} not found`);
      return;
    }

    const { companyId, seekerId, companyName, seekerName } = chatData;

    if (!companyId || !seekerId) {
      logger.warn(`Chat ${chatId} missing participant IDs`);
      return;
    }

    let receiverId;
    let senderDisplayName;
    let fcmToken;

    if (senderId === companyId) {
      receiverId = seekerId;
      senderDisplayName = companyName || 'Company';
      try {
        const seekerDoc = await db.collection('jobSeekers').doc(seekerId).get();
        fcmToken = seekerDoc.data()?.fcmToken;
      } catch (err) {
        logger.error(`Failed to read jobSeeker doc for ${seekerId}`, err);
      }
    } else if (senderId === seekerId) {
      receiverId = companyId;
      senderDisplayName = seekerName || 'Job Seeker';
      try {
        const companyDoc = await db.collection('companies').doc(companyId).get();
        fcmToken = companyDoc.data()?.fcmToken;
      } catch (err) {
        logger.error(`Failed to read company doc for ${companyId}`, err);
      }
    } else {
      logger.warn(
        `Sender ${senderId} is neither company nor seeker in chat ${chatId}`,
      );
      return;
    }

    if (senderId === receiverId) {
      logger.warn(`Sender and receiver are the same in chat ${chatId}, skipping`);
      return;
    }

    const messageText = data.text || '';
    if (!messageText) {
      logger.warn('Empty message text, skipping notification');
      return;
    }

    // FCM push is best-effort
    if (!fcmToken) {
      logger.warn(`No FCM token for receiver ${receiverId}`);
      return;
    }

    const message = {
      data: {
        type: 'chat_message',
        title: senderDisplayName,
        body: messageText,
        chatId,
        senderId,
      },
      token: fcmToken,
    };

    logger.info(`onNewChatMessage: FCM token for receiver ${receiverId}: "${fcmToken}" (len=${fcmToken.length})`);
    try {
      const response = await admin.messaging().send(message);
      logger.info(`onNewChatMessage: FCM send SUCCESS to receiver ${receiverId}, response: ${JSON.stringify(response)}`);
    } catch (err) {
      logger.error(`onNewChatMessage: FCM send FAILED for receiver ${receiverId}: ${err.message} (code=${err.code})`);
    }
  },
);

// ─────────────────────────────────────────────
// Function 5: Analyze CV (callable)
// ─────────────────────────────────────────────
function downloadFile(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (response) => {
      if (response.statusCode !== 200) {
        reject(new Error(`Download failed with status ${response.statusCode}`));
        return;
      }
      const chunks = [];
      response.on('data', (chunk) => chunks.push(chunk));
      response.on('end', () => resolve(Buffer.concat(chunks)));
      response.on('error', reject);
    }).on('error', reject);
  });
}

// ─────────────────────────────────────────────
// Shared helper: extract text from PDF via Document AI OCR
// ─────────────────────────────────────────────
async function extractTextFromPdf(pdfBuffer) {
  const { DocumentProcessorServiceClient } = require('@google-cloud/documentai').v1;
  const client = new DocumentProcessorServiceClient();
  const processorName = 'projects/429003921296/locations/us/processors/f58882556c285858';
  const request = {
    name: processorName,
    rawDocument: {
      content: pdfBuffer.toString('base64'),
      mimeType: 'application/pdf',
    },
  };
  const [result] = await client.processDocument(request);
  const text = (result.document.text || '').trim();

  if (text.length < 100) {
    throw new Error('CV could not be read. Please upload a text-based PDF that contains selectable text, not a scanned image.');
  }

  return text;
}

// ─────────────────────────────────────────────
// Function 6: Rank candidates (callable)
// ─────────────────────────────────────────────
exports.rankCandidates = onCall({ secrets: ['GROQ_API_KEY'], memory: '1GiB', timeoutSeconds: 120 }, async (request) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  const { candidates, jobDescription } = request.data;

  if (!candidates || !Array.isArray(candidates) || !jobDescription) {
    throw new HttpsError('invalid-argument', 'candidates (array) and jobDescription (string) are required');
  }

  logger.info('rankCandidates received', {
    seekerIds: candidates.map((c) => c.seekerId),
    jobDescriptionLength: jobDescription.length,
    candidateCount: candidates.length,
  });

  const results = await Promise.all(candidates.map(async (candidate) => {
    const { seekerId, cvUrl } = candidate;

    const hasCv = Boolean(cvUrl && cvUrl.toString().trim().length > 0);
    logger.info(`rankCandidates processing candidate`, { seekerId, hasCv, cvUrlLength: cvUrl?.length ?? 0 });

    if (!hasCv) {
      logger.warn(`rankCandidates no CV for seeker ${seekerId}`);
      return { seekerId, match_percentage: 0, strengths: [], weaknesses: [], suggestions: ['No CV provided'] };
    }

    try {
      const pdfBuffer = await downloadFile(cvUrl);
      const cvText = await extractTextFromPdf(pdfBuffer);

      logger.info(`rankCandidates CV parsed for seeker ${seekerId}`, { textLength: cvText.length });

      const completion = await groq.chat.completions.create({
        model: 'llama-3.3-70b-versatile',
        messages: [
          {
            role: 'system',
            content: 'You are an expert CV analyzer. Analyze the CV against the job description and return a JSON object with: match_percentage (number 0-100), strengths (array of strings), weaknesses (array of strings), suggestions (array of strings). Respond with valid JSON only.',
          },
          {
            role: 'user',
            content: `CV TEXT:\n${cvText}\n\nJOB DESCRIPTION:\n${jobDescription}`,
          },
        ],
        response_format: { type: 'json_object' },
      });

      const analysis = JSON.parse(completion.choices[0].message.content);

      logger.info(`rankCandidates Groq result for seeker ${seekerId}`, {
        match_percentage: analysis.match_percentage,
        strengthsCount: analysis.strengths?.length ?? 0,
        weaknessesCount: analysis.weaknesses?.length ?? 0,
      });

      return {
        seekerId,
        match_percentage: analysis.match_percentage,
        strengths: analysis.strengths,
        weaknesses: analysis.weaknesses,
        suggestions: analysis.suggestions,
      };
    } catch (error) {
      logger.error(`rankCandidates FAILED for seeker ${seekerId}: ${error.message}`, {
        seekerId,
        errorMessage: error.message,
        errorStack: error.stack,
      });
      return {
        seekerId,
        match_percentage: 0,
        strengths: [],
        weaknesses: [],
        suggestions: ['Analysis failed'],
      };
    }
  }));

  results.sort((a, b) => b.match_percentage - a.match_percentage);

  logger.info('rankCandidates final sorted results', {
    results: results.map((r) => ({ seekerId: r.seekerId, match_percentage: r.match_percentage })),
  });

  return results;
});

// ─────────────────────────────────────────────
// Function 7: Get job recommendations (callable)
// ─────────────────────────────────────────────
exports.getJobRecommendations = onCall({ secrets: ['GROQ_API_KEY'], memory: '1GiB', timeoutSeconds: 120 }, async (request) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  const { uid } = request.data;
  const authUid = request.auth?.uid;

  logger.info('getJobRecommendations called', { uid, authUid });

  if (!authUid) {
    throw new HttpsError('unauthenticated', 'Authentication required');
  }

  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required');
  }

  if (uid !== authUid) {
    throw new HttpsError('permission-denied', 'uid does not match authenticated user');
  }

  // Fetch user profile
  let userData;
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }
    userData = userDoc.data();
  } catch (err) {
    logger.error('Failed to fetch user profile', err);
    throw new HttpsError('not-found', 'User profile not found');
  }

  // Fetch all open jobs
  let jobs = [];
  try {
    const jobsSnapshot = await db
      .collection('jobs')
      .where('status', '==', 'Open')
      .get();
    jobs = jobsSnapshot.docs.map((doc) => ({ jobId: doc.id, ...doc.data() })).filter((j) => !j.isDeleted);
  } catch (err) {
    logger.error('Failed to fetch jobs', err);
    throw new HttpsError('internal', 'Failed to fetch jobs');
  }

  if (jobs.length === 0) {
    logger.info('No open jobs found, returning empty recommendations');
    return [];
  }

  // Build profile summary for the prompt
  const skills = userData.skills || [];
  const experience = userData.experience || [];
  const education = userData.education || [];
  const languages = userData.languages || [];
  const about = userData.about || '';
  const links = userData.links || [];

  const profileSummary = `
About: ${about}
Skills: ${skills.join(', ')}
Experience: ${experience.map((e) => `${e.position} at ${e.company}: ${e.description}`).join(' | ')}
Education: ${education.map((e) => `${e.degree} in ${e.field} from ${e.school}`).join(' | ')}
Languages: ${languages.map((l) => `${l.name} (${l.level})`).join(', ')}
Links: ${links.map((l) => `${l.type}: ${l.url}`).join(', ')}
  `.trim();

  // Build jobs summary
  const jobsSummary = jobs.map((j) =>
    `Job ID: ${j.jobId}\nTitle: ${j.title}\nDescription: ${j.description}\nRequirements: ${j.requirements}\nField: ${j.mainFieldName}\nSpecialization: ${j.subFieldName}\nLocation: ${j.location}\nSalary: ${j.salary}\nType: ${j.jobType}\nWork Mode: ${j.workMode}`
  ).join('\n\n---\n\n');

  const prompt = `You are an expert job recommendation system. Compare the following job seeker profile against each job listing and determine how well each job matches the candidate.

PROFILE:
${profileSummary}

JOBS:
${jobsSummary}

For each job, return a match percentage (0-100) and 2-4 short reasons explaining why it matches or doesn't match. Focus on skills alignment, experience relevance, education fit, and language proficiency.

Return a JSON object with a single key "recommendations" containing an array of objects, each with: jobId (string), matchPercentage (number), reasons (array of strings).

Sort the array by matchPercentage descending. Return at most 10 recommendations. Only include jobs with matchPercentage > 0.`;

  try {
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: 'You are a job recommendation engine. Respond with valid JSON only using the requested format.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      response_format: { type: 'json_object' },
    });

    const raw = completion.choices[0].message.content;
    const parsed = JSON.parse(raw);
    const recommendations = (parsed.recommendations || [])
      .filter((r) => r.jobId && r.matchPercentage > 0)
      .sort((a, b) => b.matchPercentage - a.matchPercentage)
      .slice(0, 10)
      .map((r) => ({
        jobId: r.jobId,
        matchPercentage: Math.round(r.matchPercentage),
        reasons: (r.reasons || []).slice(0, 4),
      }));

    logger.info('getJobRecommendations results', {
      uid,
      count: recommendations.length,
      topJobIds: recommendations.slice(0, 3).map((r) => r.jobId),
    });

    return recommendations;
  } catch (error) {
    logger.error('getJobRecommendations Groq call failed', error);
    throw new HttpsError('internal', `Failed to generate recommendations: ${error.message}`);
  }
});

exports.analyzeCv = onCall({ secrets: ['GROQ_API_KEY'], memory: '1GiB', timeoutSeconds: 120 }, async (request) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  const { cvUrl, jobDescription } = request.data;

  if (!cvUrl || !jobDescription) {
    throw new HttpsError('invalid-argument', 'cvUrl and jobDescription are required');
  }

  try {
    const pdfBuffer = await downloadFile(cvUrl);
    const cvText = await extractTextFromPdf(pdfBuffer);

    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: 'You are an expert CV analyzer. Analyze the CV against the job description and return a JSON object with: match_percentage (number 0-100), strengths (array of strings), weaknesses (array of strings), suggestions (array of strings). Respond with valid JSON only.',
        },
        {
          role: 'user',
          content: `CV TEXT:\n${cvText}\n\nJOB DESCRIPTION:\n${jobDescription}`,
        },
      ],
      response_format: { type: 'json_object' },
    });

    const analysis = JSON.parse(completion.choices[0].message.content);

    return {
      match_percentage: analysis.match_percentage,
      strengths: analysis.strengths,
      weaknesses: analysis.weaknesses,
      suggestions: analysis.suggestions,
    };
  } catch (error) {
    logger.error('analyzeCv failed:', error);
    throw new HttpsError('internal', `Failed to analyze CV: ${error.message}`);
  }
});
