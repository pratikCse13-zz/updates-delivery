import nodemailer, { SentMessageInfo } from "nodemailer";
import SES from "aws-sdk/clients/ses";

export default class EmailService {
  private readonly transporter: nodemailer.Transporter;

  constructor(ses: SES) {
    this.transporter = EmailService.createTransporter(ses);
  }

  private static createTransporter(sesClient: SES) {
    return nodemailer.createTransport({
      SES: sesClient
    });
  }

  public async sendMail(
    mail: nodemailer.SendMailOptions
  ): Promise<SentMessageInfo | Error> {
    return this.transporter.sendMail(mail);
  }
}
