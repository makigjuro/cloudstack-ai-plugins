using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace Starter.Shared.Infrastructure.Authentication;

public static class AuthenticationExtensions
{
    /// <summary>
    /// Registers JWT bearer authentication (Auth:Authority / Auth:Audience) and authorization.
    /// When ASPNETCORE_ENVIRONMENT=Development AND Auth:DevBypass=true, registers
    /// <see cref="DevelopmentAuthHandler"/> instead. Enabling the bypass in any other
    /// environment fails startup.
    /// </summary>
    public static WebApplicationBuilder AddStarterAuthentication(this WebApplicationBuilder builder)
    {
        ArgumentNullException.ThrowIfNull(builder);

        var devBypass = builder.Configuration.GetValue<bool>($"{AuthSettings.SectionName}:{nameof(AuthSettings.DevBypass)}");
        if (devBypass && !builder.Environment.IsDevelopment())
        {
            throw new InvalidOperationException(
                "Auth:DevBypass can only be enabled when ASPNETCORE_ENVIRONMENT=Development.");
        }

        if (devBypass)
        {
            builder.Services
                .AddAuthentication(DevelopmentAuthHandler.SchemeName)
                .AddScheme<AuthenticationSchemeOptions, DevelopmentAuthHandler>(DevelopmentAuthHandler.SchemeName, null);
        }
        else
        {
            builder.Services
                .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
                .AddJwtBearer();

            // Configured lazily so tests and hosts can supply Auth:* settings at any configuration stage.
            builder.Services
                .AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
                .Configure<IConfiguration, IHostEnvironment>((options, configuration, environment) =>
                {
                    var settings = configuration.GetSection(AuthSettings.SectionName).Get<AuthSettings>() ?? new AuthSettings();

                    options.Authority = settings.Authority;
                    options.Audience = settings.Audience;
                    options.MapInboundClaims = false;
                    options.RequireHttpsMetadata = !environment.IsDevelopment();
                    options.TokenValidationParameters.ValidateIssuer = true;
                    options.TokenValidationParameters.ValidateAudience = true;
                    options.TokenValidationParameters.ValidateLifetime = true;
                    options.TokenValidationParameters.ValidateIssuerSigningKey = true;
                    options.TokenValidationParameters.ValidAudience = settings.Audience;
                    options.TokenValidationParameters.ClockSkew = TimeSpan.FromMinutes(2);
                    options.TokenValidationParameters.NameClaimType = StarterClaimTypes.Name;
                })
                .Validate(
                    options => !string.IsNullOrWhiteSpace(options.Authority) && !string.IsNullOrWhiteSpace(options.Audience),
                    "Auth:Authority and Auth:Audience must be configured.")
                .ValidateOnStart();
        }

        builder.Services.AddAuthorization();
        return builder;
    }
}
