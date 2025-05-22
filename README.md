# status_card_list

A reusable Flutter package for displaying and organizing items as cards within lists. This package is designed to be generic and adaptable for various applications, with its initial development tailored for [ContractMatch](#contractmatch-use-case), a project that presents contracts matching a company's capability sets.

## Purpose

`status_card_list` provides a flexible and customizable UI component for Flutter applications that need to display items in a card-based list format. It supports features like task names, due dates, and basic interaction elements, making it suitable for task management, status tracking, or any scenario requiring organized, card-based layouts.

## Current Functionality

- Displays a list of items as cards with a dark-themed UI.
- Each card includes:
  - A title (e.g., "Task 1", "Task 2").
  - A subtitle for additional details (e.g., "Due today", "Due tomorrow").
  - Interaction elements such as a checkbox and a menu icon for actions like completion or deletion.
- Runs locally for development and testing across multiple platforms (web, desktop, mobile).

## Getting Started

This package can be integrated into any Flutter project requiring a card-based list interface. Follow these steps to use it in your project:

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.29.2 or later recommended).
- [Dart](https://dart.dev/get-dart) (included with Flutter).
- A code editor (e.g., Visual Studio Code with Flutter extension).

### Installation

1. Clone the repository for development or testing:
   ```bash
   git clone <your-repo-url>
   cd status_card_list