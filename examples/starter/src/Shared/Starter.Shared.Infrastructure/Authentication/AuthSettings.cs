namespace Starter.Shared.Infrastructure.Authentication;

/// <summary>Bound from the <c>Auth</c> configuration section.</summary>
public sealed class AuthSettings
{
    public const string SectionName = "Auth";

    /// <summary>OIDC authority (token issuer), e.g. https://login.microsoftonline.com/{tenant}/v2.0.</summary>
    public string? Authority { get; set; }

    /// <summary>Expected <c>aud</c> claim.</summary>
    public string? Audience { get; set; }

    /// <summary>
    /// Local development only: authenticate every request as a fixed dev user.
    /// Honoured only when ASPNETCORE_ENVIRONMENT=Development; startup fails if set anywhere else.
    /// </summary>
    public bool DevBypass { get; set; }
}
