#!/usr/bin/env swift

// Simple test script to verify authentication logic
// Run with: swift test_authentication.swift

// Mock the admin detection logic
func determineUserRole(email: String, adminCode: String?) -> String {
    let adminEmails = ["test@gmail.com"]
    let adminCodeValue = "test_admin_test"
    
    // Check if email is in admin list
    if adminEmails.contains(email) {
        return "admin"
    }
    
    // Check if admin code matches
    if let code = adminCode, code == adminCodeValue {
        return "admin"
    }
    
    return "user"
}

// Test cases
print("🧪 Testing Authentication Logic")
print(String(repeating: "=", count: 50))

// Test 1: Regular user signup
let regularUser = determineUserRole(email: "user@example.com", adminCode: nil)
print("Test 1 - Regular user (user@example.com): \(regularUser)")

// Test 2: Admin user with email
let adminUserEmail = determineUserRole(email: "test@gmail.com", adminCode: nil)
print("Test 2 - Admin user with email (test@gmail.com): \(adminUserEmail)")

// Test 3: Admin user with code
let adminUserCode = determineUserRole(email: "anyone@example.com", adminCode: "test_admin_test")
print("Test 3 - Admin user with code (anyone@example.com + test_admin_test): \(adminUserCode)")

// Test 4: Regular user with wrong code
let regularUserWrongCode = determineUserRole(email: "user@example.com", adminCode: "wrong_code")
print("Test 4 - Regular user with wrong code: \(regularUserWrongCode)")

// Test 5: Admin user with both email and code
let adminUserBoth = determineUserRole(email: "test@gmail.com", adminCode: "test_admin_test")
print("Test 5 - Admin user with both email and code: \(adminUserBoth)")

print(String(repeating: "=", count: 50))
print("✅ Authentication logic tests completed!") 