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
      const pdfParse = require('pdf-parse');
      const pdfData = await pdfParse(pdfBuffer);
      const cvText = pdfData.text.trim();

      logger.info(`rankCandidates CV parsed for seeker ${seekerId}`, { textLength: cvText.length });

      if (cvText.length < 100) {
        logger.warn(`rankCandidates CV too short for seeker ${seekerId}`, { textLength: cvText.length });
        return {
          seekerId,
          match_percentage: 0,
          strengths: [],
          weaknesses: ['CV could not be read. Please upload a text-based PDF.'],
          suggestions: ['Upload a PDF that contains selectable text, not a scanned image.'],
        };
      }

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

exports.analyzeCv = onCall({ secrets: ['GROQ_API_KEY'], memory: '1GiB', timeoutSeconds: 120 }, async (request) => {
  const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
  const { cvUrl, jobDescription } = request.data;

  if (!cvUrl || !jobDescription) {
    throw new HttpsError('invalid-argument', 'cvUrl and jobDescription are required');
  }

  try {
    const pdfBuffer = await downloadFile(cvUrl);
    const pdfParse = require('pdf-parse');
    const pdfData = await pdfParse(pdfBuffer);
    const cvText = pdfData.text.trim();

    if (cvText.length < 100) {
      logger.warn('analyzeCv CV too short', { textLength: cvText.length });
      throw new HttpsError(
        'invalid-argument',
        'CV could not be read. Please upload a text-based PDF that contains selectable text, not a scanned image.',
      );
    }

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
