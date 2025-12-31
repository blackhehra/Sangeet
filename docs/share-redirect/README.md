# Sangeet Share Redirect Page

This is a simple HTML page that redirects `https://` links to the Sangeet app using the `sangeet://` deep link scheme.

## Why is this needed?

Messaging apps like WhatsApp, Telegram, etc. only auto-link `http://` and `https://` URLs. Custom schemes like `sangeet://` appear as plain text and aren't clickable.

This redirect page solves that by:
1. Hosting a simple webpage at `https://yourusername.github.io/sangeet-share`
2. When users click the link, the page automatically redirects to `sangeet://share/...`
3. If the app isn't installed, it shows a download button

## Setup Instructions

### 1. Create a GitHub Repository

Create a new repository named `sangeet-share` (or any name you prefer).

### 2. Upload the HTML file

Upload `index.html` to the repository root.

### 3. Enable GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Under "Source", select **Deploy from a branch**
3. Select **main** branch and **/ (root)** folder
4. Click **Save**

Your page will be available at: `https://yourusername.github.io/sangeet-share`

### 4. Update the App

In `lib/services/sharing/link_share_service.dart`, update the `webRedirectBase` constant:

```dart
static const String? webRedirectBase = 'https://yourusername.github.io/sangeet-share';
```

### 5. Rebuild the App

```bash
flutter build apk --debug
```

## How it works

1. App generates share link: `https://yourusername.github.io/sangeet-share#<encoded_data>`
2. User shares this link in WhatsApp/Telegram (it's clickable!)
3. Recipient taps the link → opens the redirect page
4. Page automatically redirects to `sangeet://share/<encoded_data>`
5. Sangeet app opens and imports the shared content

## Customization

You can customize the redirect page:
- Change the logo/branding
- Update the download link to your APK release page
- Add app store links when available
