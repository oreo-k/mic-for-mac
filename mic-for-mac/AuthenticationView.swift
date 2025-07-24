import SwiftUI

struct AuthenticationView: View {
    @StateObject private var supabaseService = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var adminCode = ""
    @State private var isSignUp = false
    @State private var showingAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("mic-for-mac")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Confirm password field (only for sign up)
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Admin code field (optional, only for sign up)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Admin Code (Optional)")
                                .font(.headline)
                            TextField("Enter admin code if you have one", text: $adminCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: performAuthentication) {
                        HStack {
                            if supabaseService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(supabaseService.isLoading || !isFormValid)
                    .onTapGesture {
                        if !isFormValid {
                            print("🔍 Form validation failed:")
                            print("  Email valid: \(!email.isEmpty && email.contains("@"))")
                            print("  Password valid: \(password.count >= 6)")
                            print("  Password length: \(password.count)")
                            if isSignUp {
                                print("  Passwords match: \(password == confirmPassword)")
                            }
                        }
                    }
                    
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                    .disabled(supabaseService.isLoading)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(supabaseService.errorMessage ?? "An error occurred")
            }
            .onChange(of: supabaseService.isAuthenticated) { isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        } else {
            return emailValid && passwordValid
        }
    }
    
    private func performAuthentication() {
        guard isFormValid else { return }
        
        print("🔐 Starting authentication...")
        print("  Email: \(email)")
        print("  Password length: \(password.count)")
        print("  Admin code: \(adminCode.isEmpty ? "none" : adminCode)")
        
        Task {
            do {
                if isSignUp {
                    let code = adminCode.isEmpty ? nil : adminCode
                    print("📝 Attempting sign up...")
                    _ = try await supabaseService.signUp(email: email, password: password, adminCode: code)
                    print("✅ Sign up successful!")
                } else {
                    print("🔑 Attempting sign in...")
                    _ = try await supabaseService.signIn(email: email, password: password)
                    print("✅ Sign in successful!")
                }
            } catch {
                print("❌ Authentication error: \(error)")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error description: \(error.localizedDescription)")
                
                await MainActor.run {
                    showingAlert = true
                }
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
} 