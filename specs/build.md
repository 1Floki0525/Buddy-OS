# Buddy-OS Build Spec (High Level)

Goal: produce a Ventoy-bootable ISO that installs Buddy-OS.

## Core Constraints
- Ubuntu Core base: immutable, snap-based system
- Buddy-OS ships as a curated set of snaps + policies
- End users configure Buddy via GUI settings only
- Secrets stored in OS secure storage (not plaintext)

## Build Outputs
- Installer ISO (Ventoy compatible)
- Installed system includes:
  - Base OS snaps
  - Desktop/session stack
  - Buddy components
  - Buddy AI Settings integration

## Build Approach (Phased)

### Phase 1: Dev Environment + Reproducible Build Host
- Define a dedicated build machine or container workflow
- Pin tool versions for reproducibility
- Track everything in git and checkpoint frequently

### Phase 2: Buddy-OS Components as Snaps
Ship Buddy-OS in separate snaps to keep responsibilities clean:
- buddy-ui (Buddy Bar + Drawer)
- buddy-core (agent, memory, model router)
- buddy-actions (task execution, consent enforcement, audit log)
- buddy-settings (OS Settings integration page)

### Phase 3: Desktop Session Strategy
Two routes (final selection later):
A) Ubuntu Core Desktop base + Buddy-OS UI layer
B) COSMIC-like session packaged for Core

Buddy-OS must remain responsive and low resource at idle.

### Phase 4: Image Assembly
- Define the curated snap set
- Lock versions for stability
- Ensure permissions/interfaces match the Buddy AI access dial defaults

### Phase 5: Installer ISO
- Create an installable ISO that writes Buddy-OS to disk
- First boot includes:
  - onboarding
  - Buddy restricted-by-default
  - optional provider connect steps in Buddy AI Settings

## Acceptance Criteria
- ISO boots via Ventoy
- Installs successfully
- Desktop loads with Buddy Bar visible
- Buddy AI Settings present in OS Settings
- Local provider works without internet
- Permission dial + folder rules enforce correctly
- Audit log records actions with redaction
