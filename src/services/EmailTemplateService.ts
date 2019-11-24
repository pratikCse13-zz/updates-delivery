import nodemailer from "nodemailer";
import EmailService from "./EmailService";
import Update from "../models/Update";

export default class EmailTemplateService {
  private readonly emailService: EmailService;
  private readonly EMAIL_SENDER_ADDRESS: string;

  constructor(emailService: EmailService, emailSenderAddress: string) {
    this.emailService = emailService;
    this.EMAIL_SENDER_ADDRESS = emailSenderAddress;
  }

  public async sendUpdate(update: Update): Promise<void> {
    const { message, recipientEmail } = update;

    const htmlMessage = message.replace(/\n/g, "<br>");

    const mailOptions: nodemailer.SendMailOptions = {
      to: recipientEmail,
      from: this.EMAIL_SENDER_ADDRESS,
      subject: `Update from provider`,
      html: htmlMessage,
      text: message
    };

    await this.emailService.sendMail(mailOptions);
  }
}
