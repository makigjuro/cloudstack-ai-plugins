# CLAUDE.md

## Project Overview

<!-- Replace this with your project description -->
Brief description of your project.

## Tech Stack

<!-- Update to match your actual stack -->
- **Backend:** .NET 9, C# 13, hexagonal architecture
- **CQRS/Messaging:** WolverineFx
- **Data:** EF Core + PostgreSQL
- **Frontend:** React 18+, TypeScript, shadcn/ui, TanStack Query, Zustand, Vite
- **Infra:** Terraform, Helm, GitHub Actions

## Repository Structure

<!-- Update paths to match your project -->
```
src/
├── YourProject.sln
├── Shared/YourProject.Domain/        # Shared domain
├── Shared/YourProject.Shared.Infrastructure/  # Shared infra
├── ServiceOne/                       # Microservice
└── ServiceTwo/                       # Microservice

web/          # React frontend
deploy/       # Helm charts
infra/        # Terraform
```

## Common Commands

```bash
# Build & test
dotnet build src/YourProject.sln
dotnet test src/YourProject.sln

# Frontend
cd web && npm install && npm run dev

# Infrastructure
helm lint deploy/charts/*
terraform fmt -check -recursive infra
```

## Plugins

This project uses [cloudstack-ai-plugins](https://github.com/makigjuro/cloudstack-ai-plugins). Configuration is in `cloudstack.json` at the project root.

Available skills:
- `/dotnet-architect:add-entity` — Scaffold domain entities
- `/dotnet-architect:add-command` — Scaffold CQRS commands
- `/dotnet-architect:add-query` — Scaffold CQRS queries
- `/react-developer:add-feature` — Scaffold frontend features
- `/cloud-infra:add-helm-chart` — Scaffold Helm charts
- `/dev-workflow:complete-task` — Run full quality gates and create PR
