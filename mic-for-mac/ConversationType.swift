import Foundation

enum ConversationType: String, CaseIterable, Identifiable, Codable {
    case personal = "personal"
    case couple = "couple"
    case veterinary = "veterinary"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .personal:
            return "Personal Speech"
        case .couple:
            return "Couple Conversation"
        case .veterinary:
            return "Veterinary Consultation"
        }
    }
    
    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .couple:
            return "person.2.fill"
        case .veterinary:
            return "heart.fill"
        }
    }
    
    var description: String {
        switch self {
        case .personal:
            return "Personal thoughts, notes, or monologue"
        case .couple:
            return "Conversation between partners"
        case .veterinary:
            return "Veterinary consultation (doctor and pet owner)"
        }
    }
    
    func systemPrompt(language: Language) -> String {
        switch (self, language) {
        case (.personal, .english):
            return "You are a thoughtful personal assistant helping to organize and summarize personal thoughts, observations, and daily activities. Focus on extracting actionable insights, important decisions, and meaningful patterns from personal reflections."
        case (.personal, .japanese):
            return "あなたは個人的な考え、観察、日常活動を整理し要約するのを手伝う思慮深いパーソナルアシスタントです。個人的な振り返りから実行可能な洞察、重要な決定、意味のあるパターンを抽出することに焦点を当ててください。"
        case (.couple, .english):
            return "You are a relationship communication assistant helping couples track important discussions, decisions, and shared goals. Focus on mutual understanding, joint decisions, and relationship-building moments."
        case (.couple, .japanese):
            return "あなたはカップルが重要な議論、決定、共有目標を追跡するのを手伝う関係コミュニケーションアシスタントです。相互理解、共同決定、関係構築の瞬間に焦点を当ててください。"
        case (.veterinary, .english):
            return "You are an expert veterinary assistant with deep knowledge of canine health and medical terminology. Your role is to create comprehensive, accurate medical summaries that help veterinarians make informed decisions and provide better care. Always consider the patient's medical history, current medications, and specific health context when analyzing consultation transcripts."
        case (.veterinary, .japanese):
            return "あなたは犬の健康と医学用語に深い知識を持つ専門の獣医アシスタントです。獣医師が適切な判断を下し、より良いケアを提供できるよう、包括的で正確な医療要約を作成することがあなたの役割です。診察記録を分析する際は、常に患者の病歴、現在の投薬、および特定の健康コンテキストを考慮してください。"
        }
    }
    
    func userPrompt(language: Language, profileInfo: String = "") -> String {
        switch (self, language) {
        case (.personal, .english):
            return """
            Please analyze this personal speech/reflection and provide a comprehensive summary:
            
            CONTEXT:
            - Date: \(Date().formatted(date: .abbreviated, time: .omitted))
            - Time: \(Date().formatted(date: .omitted, time: .shortened))
            \(profileInfo.isEmpty ? "" : "\nPROFILE CONTEXT:\n\(profileInfo)")
            
            TRANSCRIPT:
            {transcript}
            
            Please provide:
            1. **Key Insights**: Important thoughts or realizations
            2. **Decisions Made**: Any decisions or commitments mentioned
            3. **Action Items**: Tasks, goals, or next steps identified
            4. **Emotional State**: Mood or emotional observations
            5. **Patterns**: Recurring themes or concerns
            6. **Priorities**: What seems most important to the speaker
            
            Format this as a personal reference document that can help with future planning and self-reflection.
            """
        case (.personal, .japanese):
            return """
            この個人的なスピーチ/振り返りを分析し、包括的な要約を提供してください：
            
            コンテキスト：
            - 日付：\(Date().formatted(date: .abbreviated, time: .omitted))
            - 時間：\(Date().formatted(date: .omitted, time: .shortened))
            \(profileInfo.isEmpty ? "" : "\nプロフィールコンテキスト：\n\(profileInfo)")
            
            文字起こし：
            {transcript}
            
            以下を提供してください：
            1. **重要な洞察**：重要な考えや気づき
            2. **決定された事項**：言及された決定や約束
            3. **アクション項目**：特定されたタスク、目標、次のステップ
            4. **感情状態**：気分や感情の観察
            5. **パターン**：繰り返しのテーマや懸念
            6. **優先事項**：話者にとって最も重要と思われること
            
            将来の計画と自己反省に役立つ個人参考文書としてフォーマットしてください。
            """
        case (.couple, .english):
            return """
            Please summarize this couple's conversation with attention to relationship dynamics:
            
            \(profileInfo.isEmpty ? "" : "PROFILE CONTEXT:\n\(profileInfo)\n")
            
            TRANSCRIPT:
            {transcript}
            
            Please provide:
            1. **Topics Discussed**: Main subjects and themes
            2. **Decisions Made**: Joint decisions or agreements
            3. **Plans Mentioned**: Future plans or commitments
            4. **Concerns Raised**: Any worries or issues discussed
            5. **Positive Moments**: Appreciation, support, or connection moments
            6. **Action Items**: Tasks or follow-ups for either partner
            7. **Communication Notes**: How well they communicated or areas for improvement
            
            Format this as a relationship reference that helps track progress and maintain shared understanding.
            """
        case (.couple, .japanese):
            return """
            関係性のダイナミクスに注意してこのカップルの会話を要約してください：
            
            \(profileInfo.isEmpty ? "" : "プロフィールコンテキスト：\n\(profileInfo)\n")
            
            文字起こし：
            {transcript}
            
            以下を提供してください：
            1. **議論されたトピック**：主要な主題とテーマ
            2. **決定された事項**：共同決定や合意
            3. **言及された計画**：将来の計画や約束
            4. **提起された懸念**：議論された心配や問題
            5. **ポジティブな瞬間**：感謝、サポート、またはつながりの瞬間
            6. **アクション項目**：どちらかのパートナーのタスクやフォローアップ
            7. **コミュニケーションノート**：どれだけよくコミュニケーションしたか、または改善の領域
            
            進捗を追跡し、共有理解を維持するのに役立つ関係参考としてフォーマットしてください。
            """
        case (.veterinary, .english):
            return """
            Create a detailed veterinary consultation summary using the following information:
            
            PATIENT PROFILE:
            \(profileInfo.isEmpty ? "No profile information available" : profileInfo)
            
            CONSULTATION TRANSCRIPT:
            {transcript}
            
            Please provide a structured summary including:
            1. **Chief Complaint**: Main reason for visit
            2. **Clinical Findings**: Key observations and symptoms discussed
            3. **Assessment**: Potential diagnoses or conditions mentioned
            4. **Treatment Plan**: Medications, procedures, or recommendations
            5. **Follow-up Instructions**: Next steps, monitoring, or recheck schedule
            6. **Owner Education**: Important information shared with pet owner
            7. **Action Items**: Specific tasks or decisions that need follow-up
            
            Format the summary professionally for medical records, highlighting any changes from previous visits and noting any concerns that require immediate attention.
            """
        case (.veterinary, .japanese):
            return """
            以下の情報を使用して詳細な獣医診察要約を作成してください：
            
            患者プロフィール：
            \(profileInfo.isEmpty ? "プロフィール情報が利用できません" : profileInfo)
            
            診察記録：
            {transcript}
            
            以下の構造化された要約を提供してください：
            1. **主訴**：来院の主な理由
            2. **臨床所見**：議論された主要な観察と症状
            3. **評価**：言及された潜在的な診断または状態
            4. **治療計画**：投薬、処置、または推奨事項
            5. **フォローアップ指示**：次のステップ、モニタリング、または再検査スケジュール
            6. **飼い主教育**：ペットの飼い主と共有された重要な情報
            7. **アクション項目**：フォローアップが必要な特定のタスクまたは決定
            
            医療記録用に専門的にフォーマットし、前回の診察からの変更点を強調し、即座の注意が必要な懸念事項を記録してください。
            """
        }
    }
    
    var placeholderText: String {
        switch self {
        case .personal:
            return "Select 'Personal Speech' for individual thoughts, notes, or monologues"
        case .couple:
            return "Select 'Couple Conversation' for discussions between partners"
        case .veterinary:
            return "Select 'Veterinary Consultation' for doctor-pet owner conversations"
        }
    }
    
    // MARK: - Profile Information Helper
    func formatProfileInfo(dogProfile: DogProfile?, multiOwnerProfile: MultiOwnerProfile?) -> String {
        var profileInfo = ""
        
        if let dog = dogProfile {
            profileInfo += """
            DOG INFORMATION:
            - Name: \(dog.name.isEmpty ? "Not specified" : dog.name)
            - Breed: \(dog.breed.isEmpty ? "Not specified" : dog.breed)
            - Age: \(dog.ageDescription)
            - Weight: \(dog.weight > 0 ? "\(dog.weight) lbs" : "Not specified")
            - Color: \(dog.color.isEmpty ? "Not specified" : dog.color)
            - Microchip: \(dog.microchipNumber.isEmpty ? "Not specified" : dog.microchipNumber)
            """
            
            if !dog.currentMedications.isEmpty {
                profileInfo += "\n- Current Medications:"
                for med in dog.currentMedications where med.isActive {
                    profileInfo += "\n  * \(med.name) - \(med.dosage) \(med.frequency)"
                }
            }
            
            if !dog.allergies.isEmpty {
                profileInfo += "\n- Allergies: \(dog.allergies.joined(separator: ", "))"
            }
            
            if !dog.specialNeeds.isEmpty {
                profileInfo += "\n- Special Needs: \(dog.specialNeeds)"
            }
            
            if !dog.medicalHistory.isEmpty {
                profileInfo += "\n- Recent Medical History:"
                let recentHistory = dog.medicalHistory.sorted { $0.date > $1.date }.prefix(3)
                for record in recentHistory {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    profileInfo += "\n  * \(dateFormatter.string(from: record.date)): \(record.diagnosis)"
                }
            }
        }
        
        if let multiOwner = multiOwnerProfile, !multiOwner.owners.isEmpty {
            if !profileInfo.isEmpty {
                profileInfo += "\n\n"
            }
            profileInfo += """
            OWNER INFORMATION:
            """
            
            for (index, owner) in multiOwner.owners.enumerated() {
                let ownerNumber = multiOwner.owners.count > 1 ? " \(index + 1)" : ""
                profileInfo += """
                
            Owner\(ownerNumber): \(owner.displayName)
            - Phone: \(owner.phone.isEmpty ? "Not specified" : owner.phone)
            - Email: \(owner.email.isEmpty ? "Not specified" : owner.email)
            """
                
                if !owner.preferredVeterinarian.isEmpty {
                    profileInfo += "\n- Preferred Veterinarian: \(owner.preferredVeterinarian)"
                }
                
                if !owner.preferredClinic.isEmpty {
                    profileInfo += "\n- Preferred Clinic: \(owner.preferredClinic)"
                }
                
                if !owner.notes.isEmpty {
                    profileInfo += "\n- Notes: \(owner.notes)"
                }
            }
        }
        
        return profileInfo
    }
}

enum Language: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case japanese = "ja"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .japanese:
            return "🇯🇵"
        }
    }
} 