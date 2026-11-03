using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using OpenTelemetry;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;

namespace Starter.ServiceDefaults;

/// <summary>
/// Cross-cutting defaults shared by every host: structured logging, OpenTelemetry and health checks.
/// </summary>
public static class Extensions
{
    public const string LivenessPath = "/health/live";
    public const string ReadinessPath = "/health/ready";

    /// <summary>Health checks tagged with this are evaluated by <see cref="LivenessPath"/>.</summary>
    public const string LiveTag = "live";

    /// <summary>Health checks tagged with this (e.g. database) are evaluated by <see cref="ReadinessPath"/>.</summary>
    public const string ReadyTag = "ready";

    public static TBuilder AddServiceDefaults<TBuilder>(this TBuilder builder)
        where TBuilder : IHostApplicationBuilder
    {
        ArgumentNullException.ThrowIfNull(builder);

        builder.ConfigureStructuredLogging();
        builder.ConfigureOpenTelemetry();
        builder.AddDefaultHealthChecks();
        return builder;
    }

    public static TBuilder ConfigureStructuredLogging<TBuilder>(this TBuilder builder)
        where TBuilder : IHostApplicationBuilder
    {
        // JSON console logs outside Development so container log collectors get structured fields.
        if (!builder.Environment.IsDevelopment())
        {
            builder.Logging.ClearProviders();
            builder.Logging.AddJsonConsole(options =>
            {
                options.IncludeScopes = true;
                options.UseUtcTimestamp = true;
                options.TimestampFormat = "yyyy-MM-ddTHH:mm:ss.fffZ ";
            });
        }

        return builder;
    }

    public static TBuilder ConfigureOpenTelemetry<TBuilder>(this TBuilder builder)
        where TBuilder : IHostApplicationBuilder
    {
        builder.Logging.AddOpenTelemetry(logging =>
        {
            logging.IncludeFormattedMessage = true;
            logging.IncludeScopes = true;
        });

        var otel = builder.Services.AddOpenTelemetry()
            .WithMetrics(metrics => metrics
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddRuntimeInstrumentation())
            .WithTracing(tracing => tracing
                .AddSource(builder.Environment.ApplicationName)
                .AddSource("Wolverine")
                .AddSource("Npgsql")
                .AddAspNetCoreInstrumentation(options =>
                    // Probes are noise in traces.
                    options.Filter = context =>
                        !context.Request.Path.StartsWithSegments(LivenessPath, StringComparison.OrdinalIgnoreCase)
                        && !context.Request.Path.StartsWithSegments(ReadinessPath, StringComparison.OrdinalIgnoreCase))
                .AddHttpClientInstrumentation());

        // Export only when a collector is configured (OTEL_EXPORTER_OTLP_ENDPOINT); otherwise telemetry stays in-process.
        if (!string.IsNullOrWhiteSpace(builder.Configuration["OTEL_EXPORTER_OTLP_ENDPOINT"]))
        {
            otel.UseOtlpExporter();
        }

        return builder;
    }

    public static TBuilder AddDefaultHealthChecks<TBuilder>(this TBuilder builder)
        where TBuilder : IHostApplicationBuilder
    {
        builder.Services.AddHealthChecks()
            .AddCheck("self", () => HealthCheckResult.Healthy(), [LiveTag, ReadyTag]);
        return builder;
    }

    /// <summary>
    /// Maps <c>/health/live</c> (process is up) and <c>/health/ready</c> (dependencies reachable).
    /// Both are anonymous on purpose: container platform probes do not carry credentials, and the
    /// responses contain only a status string.
    /// </summary>
    public static WebApplication MapDefaultEndpoints(this WebApplication app)
    {
        ArgumentNullException.ThrowIfNull(app);

        app.MapHealthChecks(LivenessPath, new HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains(LiveTag),
        }).AllowAnonymous();

        app.MapHealthChecks(ReadinessPath, new HealthCheckOptions
        {
            Predicate = check => check.Tags.Contains(ReadyTag),
        }).AllowAnonymous();

        return app;
    }
}
