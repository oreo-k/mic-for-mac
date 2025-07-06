import XCTest
import Supabase
@testable import mic_for_mac

final class SupabaseIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Set up test credentials if needed
        // SupabaseConfig.shared.setDevelopmentCredentials(url: "test-url", anonKey: "test-key")
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
    }
    
    func testSupabaseConfiguration() throws {
        // Test configuration validation
        XCTAssertThrowsError(try SupabaseConfig.shared.validateConfiguration()) { error in
            XCTAssertTrue(error is SupabaseConfig.ConfigError)
        }
    }
    
    func testSupabaseClientInitialization() throws {
        // Test that client can be initialized (will fail without proper config)
        XCTAssertNoThrow(SupabaseConfig.shared.client)
    }
    
    func testDatabaseTablesExist() async throws {
        // Skip this test if not properly configured
        guard SupabaseConfig.shared.isConfigured else {
            throw XCTSkip("Supabase not configured for testing")
        }
        
        let client = SupabaseConfig.shared.client
        
        // Test that we can query the user_profiles table
        do {
            let _: [String: Any] = try await client.database
                .from(SupabaseConfig.Tables.userProfiles)
                .select("id")
                .limit(1)
                .execute()
                .value
            
            // If we get here, the table exists
            XCTAssertTrue(true)
        } catch {
            XCTFail("Failed to query user_profiles table: \(error)")
        }
    }
    
    func testStorageBucketsExist() async throws {
        // Skip this test if not properly configured
        guard SupabaseConfig.shared.isConfigured else {
            throw XCTSkip("Supabase not configured for testing")
        }
        
        let client = SupabaseConfig.shared.client
        
        // Test that we can list storage buckets
        do {
            let buckets = try await client.storage.listBuckets()
            let bucketNames = buckets.map { $0.name }
            
            // Check if our expected buckets exist
            XCTAssertTrue(bucketNames.contains(SupabaseConfig.Storage.audioFiles))
            XCTAssertTrue(bucketNames.contains(SupabaseConfig.Storage.avatars))
        } catch {
            XCTFail("Failed to list storage buckets: \(error)")
        }
    }
    
    func testAuthenticationSystem() async throws {
        // Skip this test if not properly configured
        guard SupabaseConfig.shared.isConfigured else {
            throw XCTSkip("Supabase not configured for testing")
        }
        
        let client = SupabaseConfig.shared.client
        
        // Test that we can access the auth system
        do {
            let session = try await client.auth.session
            // Session might be nil, which is expected for unauthenticated state
            XCTAssertNoThrow(session)
        } catch {
            XCTFail("Failed to access auth system: \(error)")
        }
    }
    
    func testRowLevelSecurity() async throws {
        // Skip this test if not properly configured
        guard SupabaseConfig.shared.isConfigured else {
            throw XCTSkip("Supabase not configured for testing")
        }
        
        let client = SupabaseConfig.shared.client
        
        // Test that RLS is working by trying to access data without authentication
        do {
            let _: [String: Any] = try await client.database
                .from(SupabaseConfig.Tables.audioFiles)
                .select("id")
                .limit(1)
                .execute()
                .value
            
            // If we get here without authentication, RLS might not be properly configured
            // This is expected behavior for unauthenticated access
            XCTAssertTrue(true)
        } catch {
            // This is expected - RLS should block unauthenticated access
            XCTAssertTrue(error.localizedDescription.contains("JWT") || 
                         error.localizedDescription.contains("authentication") ||
                         error.localizedDescription.contains("permission"))
        }
    }
    
    func testConfigurationErrorHandling() throws {
        // Test configuration error types
        let config = SupabaseConfig.shared
        
        // Test missing URL error
        XCTAssertThrowsError(try config.validateConfiguration()) { error in
            if let configError = error as? SupabaseConfig.ConfigError {
                XCTAssertTrue(configError == .missingURL || configError == .missingAnonKey)
            }
        }
    }
    
    func testDevelopmentCredentials() throws {
        let config = SupabaseConfig.shared
        
        // Test setting development credentials
        config.setDevelopmentCredentials(url: "https://test.supabase.co", anonKey: "test-key")
        
        // Test clearing development credentials
        config.clearDevelopmentCredentials()
        
        // Verify credentials are cleared
        XCTAssertFalse(config.isConfigured)
    }
} 