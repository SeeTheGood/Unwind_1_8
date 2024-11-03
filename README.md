# Unwind - Mental Wellness Chat App

A SwiftUI-based mental wellness application designed to help users manage overthinking and negative thinking. The app leverages OpenAI’s API to provide supportive, constructive advice, mindfulness exercises, and positive reinforcement in a conversational format.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Overview

**Unwind** is a mental wellness application that provides a chat-based interface where users can interact with a supportive assistant. The app is aimed at promoting mindfulness and positive thinking through conversations that incorporate advice and exercises to help manage stress and negative thoughts.

## Features

- **Conversational Chat Interface**: Engage in a conversation with an assistant to receive guidance and exercises.
- **Mindfulness and Positivity**: Exercises and reinforcement for mindfulness and positive thinking.
- **Adaptive Responses**: The assistant can adjust its responses to user inputs based on OpenAI’s capabilities.

## Project Structure

The main files in this repository include:

- **`UnwindApp.swift`**: The entry point for the SwiftUI app, initializing the main view.
- **`ContentView.swift`**: The primary interface where users interact with the assistant.
- **`UnwindAPI.swift`**: Handles API requests to OpenAI, including message sending, thread creation, and polling for responses.
- **`ChatMessage.swift`**: Defines the `ChatMessage` model for handling chat messages between the user and the assistant.
- **`Helpers.swift`**: Contains utility functions and helpers used throughout the app.
- **`Info.plist`**: Contains app configuration settings.
- **`Unwind_1_8.entitlements`**: Defines app entitlements for necessary permissions.

## Prerequisites

- **Xcode**: Ensure Xcode is installed (version 12.0 or later).
- **Swift 5.3** or later.
- **OpenAI API Key**: Sign up for an API key from OpenAI and add it to your environment variables or directly into `UnwindAPI.swift`.


## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/SeeTheGood.git
   cd SeeTheGood

2. Open in Xcode:
Open SeeTheGood.xcodeproj in Xcode.
Configure Environment Variables:
Add your OpenAI API key to an .env file or directly in UnwindAPI.swift.
If using .env, create one in the root directory:
plaintext
Copy code
OPENAI_API_KEY=your_openai_api_key_here
Build and Run:
Select your target device or simulator in Xcode and click Run.

3. Usage
a. Launch the App:
After building and running the app, the main chat interface will appear.
b. Start a Conversation:
Type a message in the input field to start interacting with the assistant.
The app will create a conversation thread and poll for responses using the OpenAI API.
c. Receive Guidance:
The assistant will respond with supportive advice or exercises designed to help manage stress and promote positivity.
