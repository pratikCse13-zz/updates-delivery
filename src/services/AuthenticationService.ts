import { JwtService } from "./JwtService";
import { UnauthorizedError } from "../errors/UnauthorizedError";
import { CustomAuthorizerResult } from "aws-lambda/index";
import { CertSigningKey } from "jwks-rsa";

interface Secrets {
  tokenIssuer: string;
  audience: string;
}

export class AuthenticationService {
  private readonly jwtService: JwtService;
  private readonly secrets: Secrets;
  private readonly authorizedEmails: string[];
  private readonly testClientId: string;

  constructor(
    secrets: Secrets,
    jwtService: JwtService,
    authorizedEmails: string[],
    testClientId: string
  ) {
    this.jwtService = jwtService;
    this.secrets = secrets;
    this.authorizedEmails = authorizedEmails;
    this.testClientId = testClientId;
  }

  public async authenticate(
    methodArn: string,
    authorizationToken: string
  ): Promise<CustomAuthorizerResult> {
    try {
      const token = this.extractTokenString(authorizationToken);
      const verifiedPayload = await this.parseToken(token);
      const { userIsAuthorized, tokenSubject } = this.checkUserAuthorization(
        verifiedPayload
      );
      const authenticationResult = this.createAuthenticationResult(
        verifiedPayload.scope,
        methodArn,
        tokenSubject,
        userIsAuthorized
      );

      return authenticationResult;
    } catch (error) {
      console.warn(
        `Error authenticating user to ${methodArn} resource`,
        {},
        error
      );
      return {
        principalId: undefined,
        policyDocument: this.generatePolicy("Deny", methodArn)
      };
    }
  }

  protected generatePolicy(effect: "Allow" | "Deny", resource: string): any {
    return {
      Statement: [
        {
          Action: "execute-api:Invoke", // default action
          Effect: effect,
          Resource: resource
        }
      ],
      Version: "2012-10-17" // default version
    };
  }

  protected extractTokenString(authorizationToken: string) {
    const match = authorizationToken.match(
      /^Bearer ([A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*)$/
    );
    if (!match || match.length < 2) {
      throw new UnauthorizedError("Invalid Authorization token pattern");
    }
    return match[1];
  }

  protected async parseToken(jwtToken: string): Promise<any> {
    const decoded: any = this.jwtService.decode(jwtToken, { complete: true });

    const signingKey = await this.jwtService.getSigningKey(decoded);
    const key = (signingKey as CertSigningKey).publicKey;
    return this.jwtService.verify(jwtToken, key, {
      audience: this.secrets.audience,
      issuer: this.secrets.tokenIssuer
    });
  }

  private checkUserAuthorization(verifiedPayload: any) {
    const tokenSubject: string = verifiedPayload.sub;

    let userIsAuthorized: boolean;
    if (tokenSubject === this.testClientId) {
      userIsAuthorized = true;
    } else {
      const userEmail: string = this.getEmailFromPayload(verifiedPayload);
      userIsAuthorized = this.authorizedEmails.includes(
        userEmail.toLowerCase()
      );
    }

    return { userIsAuthorized, tokenSubject };
  }

  private getEmailFromPayload(verifiedPayload: any): string {
    const email: string = verifiedPayload.email || "";
    if (email === "") {
      console.error(
        "User email is not present in Auth0 access_token. Expected claim 'email' to contain an email address. Check the Auth0 rules."
      );
    }
    return email;
  }

  private createAuthenticationResult(
    scope: any,
    methodArn: string,
    principalId: string,
    allow: boolean
  ): CustomAuthorizerResult {
    const effect = allow ? "Allow" : "Deny";
    return {
      context: { scope },
      policyDocument: this.generatePolicy(effect, methodArn),
      principalId
    };
  }
}
