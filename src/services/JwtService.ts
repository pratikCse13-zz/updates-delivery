import * as jwt from "jsonwebtoken";
import { SigningKey, JwksClient } from "jwks-rsa";
import util from "util";

export class JwtService {
  private jwksClient: JwksClient;

  constructor(jwksClient: JwksClient) {
    this.jwksClient = jwksClient;
  }

  public sign(
    payload: any,
    privateKey: string,
    signOptions?: jwt.SignOptions
  ): string {
    return jwt.sign(payload, privateKey, signOptions);
  }

  public decode(
    payload: string,
    decodeOptions?: jwt.DecodeOptions
  ): null | { [key: string]: any } | string {
    return jwt.decode(payload, decodeOptions);
  }

  public verify(
    payload: string,
    publicKey: string,
    verifyOptions?: jwt.VerifyOptions
  ): any {
    return jwt.verify(payload, publicKey, verifyOptions);
  }

  public async getSigningKey(payload: any): Promise<SigningKey> {
    if (!payload || !payload.header || !payload.header.kid) {
      throw new Error("Payload does not have a kid header");
    }

    return util.promisify(this.jwksClient.getSigningKey)(payload.header.kid);
  }
}
