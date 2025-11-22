# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

This is a hybrid C#/Unity project with the following architecture:

- **src/model/** - C# class library project targeting .NET 10.0 with nullable reference types enabled
- **tests/unit/** - xUnit test project for the model library using Microsoft.NET.Test.Sdk, xunit, and coverlet.collector
- **unity/My project/** - Unity 2D game project with comprehensive 2D tooling (Animation, Sprite tools, Input System, URP, Visual Scripting)
- **doc/** - Documentation directory

The project separates business logic (model) from game engine code (Unity), enabling better testability and code organization.

## Development Commands

### C# Model Library
```bash
# Build the model library
dotnet build src/model/model.csproj

# Run unit tests
dotnet test tests/unit/unit.csproj

# Run tests with coverage
dotnet test tests/unit/unit.csproj --collect:"XPlat Code Coverage"
```

### Unity Development
Unity development should be done through the Unity Editor by opening `unity/My project/`. The project includes:

- 2D Animation and sprite tools
- Universal Render Pipeline (URP)  
- Input System for modern input handling
- Visual Scripting for node-based logic
- Timeline for cutscenes/sequences

## Testing Framework

The project uses xUnit for C# unit testing with:
- **Microsoft.NET.Test.Sdk** for test execution
- **xunit** test framework  
- **coverlet.collector** for code coverage
- **xunit.runner.visualstudio** for Visual Studio integration

Tests are located in `tests/unit/` and reference the main model project.

## Key Technologies

- **.NET 10.0** with implicit usings and nullable reference types
- **Unity 2D** with comprehensive 2D game development tools
- **xUnit** for unit testing
- **Universal Render Pipeline** for rendering
- **Unity Input System** for input handling