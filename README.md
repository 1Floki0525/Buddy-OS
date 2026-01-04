# Buddy-OS: Autonomous AI Developer Assistant

Buddy-OS is a Linux-based operating system designed to provide a fully autonomous AI developer assistant that can perform any task a human developer could do on the system.

## Features

- **Full System Access**: Buddy AI can launch applications, write files, run scripts, manage containers, and control the graphical interface.
- **Buddy Copilot**: GUI chat interface at bottom-right of desktop for text-based interaction.
- **Hey Buddy Voice Control**: Voice activation service that listens for "Hey Buddy" wake word.
- **Policy System**: Configurable access policies with "restricted" preset for developer mode.
- **GUI Automation**: Mouse, keyboard, screen capture, and window management capabilities.
- **Docker Control**: Manage containers and images.
- **Network Administration**: Configure network interfaces and monitor network status.
- **Shell Execution**: Run system commands with full privileges.

## Installation

### Prerequisites
- Linux system (Ubuntu/Debian recommended)
- Python 3.8+
- Git

### Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Buddy-OS.git
cd Buddy-OS
```

2. Install dependencies:
```bash
./build_all.sh
```

3. Start Buddy AI:
```bash
./start_buddy.sh
```

4. Test Buddy AI capabilities:
```bash
./scripts/dev/test_all_buddy.sh
```

## Usage

Once Buddy AI is running:
- Use the Buddy Copilot GUI at bottom-right of desktop to interact with Buddy via text
- Say "Hey Buddy" to activate voice control (voice service running in background)
- Buddy will execute tasks and provide feedback in real-time

## Development

### Architecture
- `broker/`: Core action execution daemon with HTTP API
- `buddy-copilot/`: GUI chat interface for user interaction
- `buddy-voice/`: Voice activation service for hands-free control
- `scripts/`: Build and development scripts
- `notes/`: Development decisions and documentation

### Testing
Run the test script to verify all capabilities:
```bash
./scripts/dev/test_all_buddy.sh
```

## Security

Buddy-OS implements a policy system to control access:
- Default policy allows "restricted" access in developer mode
- Blacklists sensitive directories (`.ssh`, `.gnupg`)
- Capabilities can be disabled via environment variables
- Action execution is logged for audit purposes
- Consent and re-auth requirements enforced for high-risk actions

## Contributing

Contributions are welcome! Please submit issues or pull requests with clear descriptions of the problem or feature.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
