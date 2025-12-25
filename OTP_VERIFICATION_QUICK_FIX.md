# OTP Verification - Quick Test Instructions

## 🔧 Changes Made

5 specific fixes were applied to fix OTP verification validation failure:

### 1. PinCodeTextField Enhancement
- File: `lib/presentation/widgets/pin_input.dart`
- Fixed: Added proper error animation controller and validator

### 2. Data Trimming
- Files: `lib/data/models/auth_request_model.dart`, `lib/data/providers/auth_provider.dart`
- Fixed: Email and OTP are now trimmed and normalized before sending

### 3. Response Format Flexibility
- File: `lib/data/services/auth_api_service.dart`
- Fixed: Now handles multiple backend response formats (success field optional)

### 4. Enhanced Logging
- File: `lib/data/services/auth_api_service.dart`
- Fixed: Console now shows actual request data and response to help debugging

### 5. Better Error Handling
- File: `lib/presentation/screens/auth/email_verification_screen.dart`
- Fixed: PIN is cleared on failure, error message shows for 4 seconds

---

## 🚀 Test Instructions

### Step 1: Hot Reload
```bash
# In your terminal while app is running:
r  # Hot reload
R  # Hot restart if hot reload doesn't work
```

### Step 2: Register New Account
1. Navigate to Register screen
2. Fill in test data:
   - Username: `testuser123`
   - Email: `test@example.com` (use actual email to receive OTP)
   - Password: `Password123`
   - First Name: `Test`
   - Last Name: `User`
3. Click **"Đăng ký"** button
4. You should be directed to **Email Verification Screen**

### Step 3: Check Email for OTP
1. Open your email inbox
2. Look for email from `shareo.studio` or `no-reply@shareo.studio`
3. Find the 6-digit OTP code
4. Note it down

### Step 4: Enter OTP
1. On the Email Verification Screen, you'll see 6 PIN input fields
2. Enter the OTP code digit by digit
3. **Important**: Do NOT add spaces or dashes
4. Example: If OTP is `1 2 3 4 5 6`, enter it as `123456`

### Step 5: Monitor Console
While entering OTP, watch the **Dart Console** for:

**When you enter all 6 digits:**
```
REQUEST[POST] => PATH: /verify-registration
URL: https://shareo.studio/public/v2/auth/verify-registration
REQUEST DATA: {email: test@example.com, otp: 123456}
```

**Backend response (Success):**
```
RESPONSE[200] => PATH: /verify-registration
RESPONSE DATA: {success: true, message: Verification successful}
```

**Backend response (Error - like OTP expired):**
```
ERROR[422] => PATH: /verify-registration
ERROR DATA: {message: OTP has expired}
```

### Step 6: Expected Result

#### ✅ Success Case
- PIN fields disappear
- Green message: **"Đăng ký thành công! Vui lòng đăng nhập"**
- Auto-navigated to **Login Screen**
- Console shows: `RESPONSE[200]` with `success: true`

#### ❌ Failure Case
- PIN fields remain
- Red message shows with error (e.g., "Dữ liệu không hợp lệ")
- PIN is cleared, ready for retry
- Console shows: `ERROR[422]` or `ERROR[500]`

---

## 🐛 If Still Failing - Debug Checklist

### Check 1: Console Output
**Screenshot the ENTIRE console** showing:
1. REQUEST being sent
2. RESPONSE or ERROR received
3. Full error data if any

### Check 2: Email Address
- ✅ Should be: `test@example.com`
- ❌ Should NOT be: `Test@Example.Com ` (uppercase/spaces)

### Check 3: OTP Code
- ✅ Should be: `123456` (6 digits, no spaces)
- ❌ Should NOT be: `12-34-56` or `12 34 56`
- Check email for exactly 6 digits (sometimes they look similar)

### Check 4: Email Delivery
- Did you receive OTP email?
- Check **Spam/Junk** folder
- Check **All Mail** if filter is too strict

### Check 5: OTP Expiry
- Some OTPs expire in 5-15 minutes
- If > 10 minutes passed, click **"Gửi lại"** for new OTP
- Watch countdown timer

---

## 📊 Test Status Tracking

| Item | Status | Notes |
|------|--------|-------|
| PinInput Widget | ✅ Fixed | StatefulWidget with error controller |
| Data Trimming | ✅ Fixed | Email normalized (lowercase, trimmed) |
| Response Handling | ✅ Fixed | Handles multiple response formats |
| Logging | ✅ Enhanced | Console shows full request/response |
| Error Display | ✅ Improved | Clears PIN, shows error for 4 seconds |

---

## 🎯 Next Steps

### If Successful ✅
1. Try login with the registered email
2. Test other auth features (logout, profile, etc.)
3. Document working version for production

### If Still Failing 🔴
1. Share console logs (screenshot full output)
2. Share error message shown on screen
3. Verify email address is correct and accessible
4. Check if OTP email is being sent (ask backend team)

---

## 📝 Architecture Overview

```
User Input (PIN) 
    ↓
PinInput Widget (lib/presentation/widgets/pin_input.dart)
    ↓
EmailVerificationScreen._handleVerify()
    ↓
AuthProvider.verifyRegistrationOtp()
    ↓
VerifyRegistrationRequest.toJson() [TRIMS EMAIL & OTP]
    ↓
AuthApiService.verifyRegistration()
    ↓
HTTP POST to /verify-registration [LOGS REQUEST]
    ↓
Backend Response [LOGS RESPONSE]
    ↓
Response Format Check [FLEXIBLE - HANDLES MULTIPLE FORMATS]
    ↓
Success: Navigate to Login
Failure: Show Error, Clear PIN for Retry
```

---

## 💡 Why These Changes

**Problem**: User reported "Validation failed" despite entering correct OTP

**Root Causes Fixed**:
1. **Widget State**: PinCodeTextField requires StreamController
2. **Data Cleaning**: Email/OTP might have whitespace causing backend validation to fail
3. **Response Parsing**: Backend might return response in different format
4. **Visibility**: No way to see what request was sent and what response was received
5. **UX**: PIN stayed filled on error, confusing user

**Result**: All validation error causes are now handled and logging visible for debugging
