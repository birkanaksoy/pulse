# Privacy Nutrition Label — App Store Connect

Pulse does not collect any user data. In App Store Connect → App Privacy, declare exactly this:

## Section 1: Data Collection
**"Do you or your third-party partners collect data from this app?"**
→ **No**

That is the entire form. Save and submit.

## Why this works

| Category | Collected? | Why we can say no |
|---|---|---|
| Contact Info (name, email, phone, address) | ❌ | No account, no email field |
| Health & Fitness | ❌ | Phone health ≠ user health; nothing leaves device |
| Financial Info | ❌ | Apple StoreKit handles payment; we never see it |
| Location | ❌ | No location API used |
| Sensitive Info | ❌ | None |
| Contacts | ❌ | No Contacts entitlement |
| User Content (photos, videos, audio, etc.) | ❌ | We read PhotoKit metadata (counts, file sizes) but transmit nothing |
| Browsing History | ❌ | No web view tracking |
| Search History | ❌ | No search |
| Identifiers (User ID, Device ID, IDFA) | ❌ | No SDK reading identifiers |
| Purchases | ❌ | StoreKit only — Apple-managed |
| Usage Data | ❌ | No analytics SDK |
| Diagnostics | ❌ | No crash reporting SDK |
| Other Data | ❌ | None |

## Privacy "Tracking" question
**"Does this app track users?"** → **No**

We do NOT:
- Link data collected about the user across other apps/websites
- Share device or user data with data brokers
- Use third-party advertising
- Display targeted ads

## Permissions declared in Info.plist

| Key | Reason shown to user |
|---|---|
| `NSPhotoLibraryUsageDescription` | "Pulse needs read access to estimate photo, video, and screenshot usage. Nothing is uploaded." |
| `NSPhotoLibraryAddUsageDescription` | "Pulse can save shareable score cards to your library." |

## Sensitive backend reminder

If we ever add a backend (e.g. for the AI doctor we removed, or for receipt validation), the Nutrition Label must be updated **before** that build ships. Reopen this file.
