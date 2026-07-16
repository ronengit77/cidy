# Escalate

## Purpose
Handle escalation requests from users who need to speak with a human colleague. Collect a brief description of the issue, generate a summary and conversation log, and send a formatted HTML email to a CDPMO colleague using the Outlook tool.

## Trigger
Use this skill when the user says something like:
- "escalate", "talk to a person", "talk to an agent", "speak to a colleague", "I need help from a human", "connect me to someone", "transfer me", "I need more help"

## Instructions

Follow these steps in order:

### Step 1 — Acknowledge
Tell the user:
> "I understand you'd like to escalate this to a colleague. I'll put together a summary and send it by email — they'll be in touch with you directly."

### Step 2 — Collect issue description
Ask the user:
> "Please briefly describe the issue or what you were unable to find:"

Wait for the user's response and store it as their issue description.

### Step 3 — Generate interaction summary
Write a concise 4–5 sentence summary of the conversation that just took place. Cover:
- What the user was looking for
- What the assistant told them
- Why it did not fully resolve their need

This summary is for a UN DESA CDPMO staff member — keep it professional and factual.

### Step 4 — Generate conversation log
Reproduce the conversation that took place, formatted exactly as:

```
USER: [what the user said]
CIDY: [what the assistant responded]
```

Include all exchanges in order. Be as verbatim as possible. Output the log only — no introduction or closing text.

### Step 5 — Build the email body
Compose an HTML email body using the template below. Replace all placeholders in `{{ }}` with the actual values:

```html
<html>
<body style="font-family: Arial, sans-serif; color: #333333; max-width: 720px; margin: 0 auto; padding: 0;">

  <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
    <tr>
      <td style="background-color: #003366; padding: 16px 24px;">
        <span style="color: #ffffff; font-size: 17px; font-weight: bold;">{{ your agent name }} &#8211; Escalated Inquiry</span>
      </td>
    </tr>
  </table>

  <div style="padding: 4px 0;">
    <p>Dear colleague,</p>
    <p>The following inquiry has been escalated from <strong>{{ your agent name }}</strong> by <strong>{{ user full name }}</strong> ({{ user email }}).</p>

    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse; margin: 16px 0;">
      <tr>
        <td style="background-color: #fff3f3; border-left: 4px solid #cc0000; padding: 12px 16px;">
          <p style="font-weight: bold; color: #cc0000; margin: 0 0 6px 0; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">Issue Description</p>
          <p style="margin: 0;">{{ user issue description }}</p>
        </td>
      </tr>
    </table>

    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse; margin: 16px 0;">
      <tr>
        <td style="background-color: #f0f5ff; border-left: 4px solid #003366; padding: 12px 16px;">
          <p style="font-weight: bold; color: #003366; margin: 0 0 6px 0; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">Interaction Summary</p>
          <p style="margin: 0;">{{ interaction summary }}</p>
        </td>
      </tr>
    </table>

    <table width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse; margin: 16px 0; border: 1px solid #dddddd;">
      <tr>
        <td style="padding: 12px 16px; background-color: #f9f9f9;">
          <p style="font-weight: bold; margin: 0 0 10px 0; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px;">Conversation Transcript</p>
          <pre style="white-space: pre-wrap; font-size: 12px; color: #444444; margin: 0; font-family: Courier New, monospace; line-height: 1.6;">{{ conversation log }}</pre>
        </td>
      </tr>
    </table>

    <p style="color: #999999; font-size: 11px; border-top: 1px solid #eeeeee; padding-top: 12px; margin-top: 16px;">
      This message was sent automatically by {{ your agent name }}.
      Please respond directly to {{ user email }} &#8212; do not reply to this email.
    </p>
  </div>

</body>
</html>
```

### Step 6 — Send the email using the Outlook tool
Call the Outlook send email tool with:
- **To:** ronen.rapoport@un.org
- **Cc:** {{ user email }}; jack.wood@un.org; jonathan.parks@un.org
- **Subject:** {{ your agent name }} – Escalated Inquiry from {{ user full name }}
- **Body:** the HTML email body composed in Step 5
- **Is HTML:** true

### Step 7 — Confirm to the user
Tell the user:
> "Done — your inquiry has been escalated and a summary has been sent by email. A CDPMO colleague will be in touch with you directly. Thank you for using Cidy!"

## Notes
- **{{ your agent name }}** should be replaced with this agent's name as defined in its instructions (e.g., "Cidy RPTC", "Cidy PD", "Cidy DA", "Cidy General"). Use the exact name — do not invent or abbreviate it.
- If the user's name or email is not available from the conversation context, omit those fields gracefully rather than leaving a visible placeholder.
- If the Outlook tool call fails, tell the user: "I was unable to send the escalation email automatically. Please contact ronen.rapoport@un.org directly and describe your issue."
- Do not escalate unless the user has explicitly asked to do so.
