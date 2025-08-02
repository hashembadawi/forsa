# Google Maps Setup Instructions

## Overview
The add ad screen now includes location selection functionality that allows users to:
1. Select their current location automatically
2. Pick a location on the map manually

## Required Setup

### 1. Get Google Maps API Key
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if targeting iOS)
   - Geocoding API (optional, for address lookup)
4. Create credentials (API Key)
5. Restrict the API key to your app's package name for security

### 2. Configure Android
The API key has been added to `android/app/src/main/AndroidManifest.xml` but you need to replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_ACTUAL_API_KEY_HERE"/>
```

### 3. Location Permissions
The following permissions have been added to AndroidManifest.xml:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

## Features Added

### Location Selection in Step 3
- Optional location selection section
- Two buttons:
  - "موقعي الحالي" (My Current Location) - Gets user's current GPS location
  - "اختر من الخريطة" (Choose from Map) - Opens map picker

### Map Location Picker
- Interactive Google Map
- Tap to select location
- Shows selected location with marker
- Confirm button to save selection

### Data Structure
The location data is sent to the server in the following format (matching your database schema):
```json
{
  "location": {
    "type": "Point",
    "coordinates": [longitude, latitude]
  }
}
```

## Usage
1. User fills in basic ad details
2. In step 3, they can optionally select a location
3. Location data is included in the ad submission if selected
4. Location is stored as GeoJSON Point in MongoDB

## Testing
To test without a real API key, you can temporarily comment out the GoogleMap widget and just test the location permission and current location functionality.
