using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Starter.Shared.Infrastructure.Authentication;

namespace Starter.Orders.Tests.Integration;

/// <summary>
/// Authenticates requests carrying <c>Authorization: Test</c>. The tenant can be chosen per client
/// with the <see cref="TenantHeader"/> header; requests without the header stay anonymous (401).
/// </summary>
public sealed class TestAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public const string SchemeName = "Test";
    public const string TenantHeader = "X-Test-Tenant";

    public TestAuthHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger, UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.Authorization.ToString().StartsWith(SchemeName, StringComparison.Ordinal))
            return Task.FromResult(AuthenticateResult.NoResult());

        Claim[] claims =
        [
            new(StarterClaimTypes.Subject, "integration-test-user"),
            new(StarterClaimTypes.Name, "Integration Test"),
            new(StarterClaimTypes.TenantId, Request.Headers[TenantHeader].ToString()),
        ];

        var identity = new ClaimsIdentity(claims, SchemeName, StarterClaimTypes.Name, "roles");
        var ticket = new AuthenticationTicket(new ClaimsPrincipal(identity), SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
