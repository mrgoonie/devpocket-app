# Container Workspace

**✅ Complete resource stack:**

- Namespaces: User-specific namespaces (`user-{user_id}`)
- Deployments: Running containers with template images
- Services: ClusterIP services exposing ports 8080 (web) and 22 (SSH)
- PersistentVolumeClaims: 10Gi storage per environment
- Security contexts: Non-root execution with proper user/group settings
- Environment Variables: User ID, environment name, and custom variables

**🌐 WebSocket Ready for Interaction:**

The infrastructure is now in place for WebSocket terminal interaction:
- Environment Status: Ready for running status
- Service Endpoints: Port 8080 exposed for WebSocket upgrades
- Terminal Access: `/api/v1/ws/terminal/{environment_id}` endpoint functional
- Authentication: JWT token-based WebSocket authentication implemented

**🔧 Technical Details:**

- SSL handling: Disabled verification for testing with self-signed certificates
- Resource management: CPU/memory requests and limits with doubling strategy
- Error handling: Comprehensive logging and status updates
- Database integration: Environment tracking with cluster and resource details

**🏠 Key Improvements Made:**

1. Home Directory Mount:
  - Changed from mounting `/workspace` to mounting `/home`
  - Full 10Gi persistent volume for user's home directory
2. User Setup:
  - Creates `devuser` with proper home directory `/home/devuser`
  - Creates `/home/devuser/workspace` subdirectory for projects
  - Sets working directory to `/home/devuser/workspace`
3. Backward Compatibility:
  - Added symlink `/workspace` → `/home/devuser/workspace`
  - Existing code expecting `/workspace` still works

**💾 Persistent Storage Structure:**

- Home PVC (10Gi): `/home` - Contains all user data:
  - User workspace files (`/home/devuser/workspace/`)
  - Configuration files (.bashrc, .profile, etc.)
  - SSH keys, Git config, and other dotfiles
  - Any user-installed tools in home directory
- System PVC (5Gi): System directories for packages:
  - `/var/lib/apt` - Package cache and lists
  - `/usr/local` - User-installed software and Python packages
  - `/opt` - Additional software installations