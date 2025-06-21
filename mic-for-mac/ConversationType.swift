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
            return "You are a helpful assistant helping to summarize personal notes and thoughts."
        case (.personal, .japanese):
            return "あなたは個人のメモや考えを要約するのを手伝うアシスタントです。"
        case (.couple, .english):
            return "You are a helpful assistant helping to summarize conversations between partners."
        case (.couple, .japanese):
            return "あなたはパートナー間の会話を要約するのを手伝うアシスタントです。"
        case (.veterinary, .english):
            return "You are a veterinary assistant helping to summarize consultation notes."
        case (.veterinary, .japanese):
            return "あなたは獣医の診察記録を要約するのを手伝う獣医アシスタントです。"
        }
    }
    
    func userPrompt(language: Language) -> String {
        switch (self, language) {
        case (.personal, .english):
            return """
            Please provide a concise summary of this personal speech or monologue. 
            Focus on key points, important thoughts, decisions made, or action items mentioned.
            Format the summary in a clear, organized manner suitable for personal reference.
            
            Transcript:
            {transcript}
            """
        case (.personal, .japanese):
            return """
            この個人的なスピーチや独白の簡潔な要約を提供してください。
            重要なポイント、重要な考え、決定された事項、または言及されたアクション項目に焦点を当ててください。
            個人の参考に適した、明確で整理された形式で要約をフォーマットしてください。
            
            文字起こし:
            {transcript}
            """
        case (.couple, .english):
            return """
            Please provide a concise summary of this couple's conversation. 
            Focus on key topics discussed, decisions made, plans mentioned, and important points for both partners.
            Format the summary in a clear, organized manner suitable for relationship reference.
            
            Transcript:
            {transcript}
            """
        case (.couple, .japanese):
            return """
            このカップルの会話の簡潔な要約を提供してください。
            議論された主要なトピック、決定された事項、言及された計画、および両パートナーにとって重要なポイントに焦点を当ててください。
            関係の参考に適した、明確で整理された形式で要約をフォーマットしてください。
            
            文字起こし:
            {transcript}
            """
        case (.veterinary, .english):
            return """
            Please provide a concise medical summary of this veterinary consultation transcript. 
            Focus on key findings, diagnoses, treatment recommendations, and follow-up instructions.
            Format the summary in a clear, professional manner suitable for medical records.
            
            Transcript:
            {transcript}
            """
        case (.veterinary, .japanese):
            return """
            この獣医診察の文字起こしの簡潔な医療要約を提供してください。
            重要な所見、診断、治療推奨事項、およびフォローアップ指示に焦点を当ててください。
            医療記録に適した、明確で専門的な形式で要約をフォーマットしてください。
            
            文字起こし:
            {transcript}
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