using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Starter.Shared.Infrastructure.Authentication;

/// <summary>
/// LOCAL DEVELOPMENT ONLY. Authenticates every request as a fixed dev user so the stack can run
/// without an identity provider. Registered only when the environment is Development and
/// Auth:DevBypass=true, and it re-checks the environment on every request as defence in depth.
/// </summary>
public sealed class DevelopmentAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "DevBypass";
    public const string DevUserId = "dev-user";
    public const string DevTenantId = "11111111-1111-1111-1111-111111111111";

    private readonly IHostEnvironment _environment;

    public DevelopmentAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IHostEnvironment environment)
        : base(options, logger, encoder)
    {
        _environment = environment;
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!_environment.IsDevelopment())
            return Task.FromResult(AuthenticateResult.Fail("Development authentication is disabled outside Development."));

        Claim[] claims =
        [
            new(StarterClaimTypes.Subject, DevUserId),
            new(StarterClaimTypes.Name, "Local Developer"),
            new(StarterClaimTypes.TenantId, DevTenantId),
        ];

        var identity = new ClaimsIdentity(claims, SchemeName, StarterClaimTypes.Name, "roles");
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
