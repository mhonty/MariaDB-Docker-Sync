## Overview
**MariaDB-Docker-Sync** is an efficient and robust shell script designed to synchronize MariaDB databases between Docker containers across different systems. This tool is specifically tailored for developers and system administrators who require a reliable and automated solution for managing database synchronization in a containerized environment. It simplifies the complexities associated with database management across multiple development, testing, and production environments, ensuring consistency and integrity of data.

## Features
- **Cross-Platform Compatibility:** Works seamlessly across all major operating systems that support Docker.
- **Automated Synchronization:** Automates the process of database synchronization, reducing manual overhead and minimizing the risk of human error.
- **Security Focused:** Implements best practices for secure database access and data transfer between systems.
- **Customizable:** Easy to configure to meet diverse system architectures and specific user requirements.

## Prerequisites
To use **MariaDB-Docker-Sync**, you need the following:
- Docker installed on all systems involved in the synchronization process.
- MariaDB running inside Docker containers.
- SSH access configured between the host systems if syncing across different machines.
- \`sshpass\` installed for password-based SSH login automation (optional, for automated setups).

## Installation
1. **Clone the Repository:**
   \`\`\`bash
   git clone git@github.com:yourusername/MariaDB-Docker-Sync.git
   cd MariaDB-Docker-Sync
   \`\`\`

2. **Set Executable Permissions:**
   \`\`\`bash
   chmod +x sync_db.sh
   \`\`\`

3. **Configure the Script:**
   Edit the \`sync_db.conf\` configuration file to specify database and Docker container details.

## Usage
To start synchronizing your databases, simply run:
\`\`\`bash
   ./sync_db.sh
\`\`\`
Ensure that you have configured all required parameters in the \`sync_db.conf\` file before executing the script. The script logs its operations, which can be reviewed for audit or troubleshooting purposes.

## Contributing
Contributions to **MariaDB-Docker-Sync** are welcome! Whether it's bug fixes, feature additions, or improvements in documentation, we appreciate your help in making this tool better. To contribute:
- Fork the repository.
- Create a new branch for your changes.
- Commit your improvements.
- Push your branch and submit a pull request.

## License
**MariaDB-Docker-Sync** is released under the MIT License. See the LICENSE file for more details.

## Support
For support, feature requests, or bug reporting, please open an issue on the GitHub repository page.
