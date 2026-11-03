using FluentAssertions.Execution;
using FluentAssertions.Primitives;
using Starter.Shared.Infrastructure.Results;

namespace Starter.Domain.Tests;

/// <summary>FluentAssertions extensions: <c>result.Should().BeSuccess()</c> / <c>.BeFailure()</c>.</summary>
public static class ResultAssertionExtensions
{
    public static ResultAssertions Should(this Result instance) => new(instance);
}

public class ResultAssertions : ReferenceTypeAssertions<Result, ResultAssertions>
{
    public ResultAssertions(Result subject) : base(subject)
    {
    }

    protected override string Identifier => "result";

    public AndConstraint<ResultAssertions> BeSuccess(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject is { IsSuccess: true })
            .FailWith("Expected {context:result} to be successful{reason}, but it failed with {0}.", Subject?.Error.Code);

        return new AndConstraint<ResultAssertions>(this);
    }

    public AndConstraint<ResultAssertions> BeFailure(string because = "", params object[] becauseArgs)
    {
        Execute.Assertion
            .BecauseOf(because, becauseArgs)
            .ForCondition(Subject is { IsFailure: true })
            .FailWith("Expected {context:result} to be a failure{reason}, but it succeeded.");

        return new AndConstraint<ResultAssertions>(this);
    }
}
