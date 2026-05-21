import Foundation

public enum ProcessingMode: String, Codable, CaseIterable, Identifiable {
    case clothingSwap = "clothing_swap"
    case environmentSwap = "environment_swap"
    case characterSwap = "character_swap"
    case fullTransformation = "full_transformation"
    
    public var id: String { self.rawValue }
    
    public var title: String {
        switch self {
        case .clothingSwap: return "Clothing Swap"
        case .environmentSwap: return "Environment Swap"
        case .characterSwap: return "Character Swap"
        case .fullTransformation: return "Full Transformation"
        }
    }
    
    public var description: String {
        switch self {
        case .clothingSwap:
            return "Swap outfits instantly while keeping the person and original background fully intact."
        case .environmentSwap:
            return "Transport your subject to any location. Keeps the person and clothing identical."
        case .characterSwap:
            return "Transform the person into a completely new custom character or stylized AI avatar."
        case .fullTransformation:
            return "Re-imagine the entire video content based on your combination of styles, references, and prompts."
        }
    }
    
    public var iconName: String {
        switch self {
        case .clothingSwap: return "tshirt.fill"
        case .environmentSwap: return "photo.on.rectangle.angled"
        case .characterSwap: return "person.and.arrow.left.and.arrow.right"
        case .fullTransformation: return "wand.and.stars"
        }
    }
    
    public var requiredReferenceCount: Int {
        switch self {
        case .clothingSwap: return 1
        case .environmentSwap: return 1 // 1 backdrop image (or optional prompt)
        case .characterSwap: return 1 // 1 character reference image
        case .fullTransformation: return 2 // Multi-modal guidance
        }
    }
    
    public var referenceImageLabel: String {
        switch self {
        case .clothingSwap: return "Outfit Reference"
        case .environmentSwap: return "Background Scenery (Optional if prompt provided)"
        case .characterSwap: return "Avatar Model Reference"
        case .fullTransformation: return "Style & Character Assets"
        }
    }
    
    public var promptPlaceholder: String {
        switch self {
        case .clothingSwap: return "E.g., 'A luxurious crimson velvet evening suit'"
        case .environmentSwap: return "E.g., 'A cyberpunk street at night with neon puddles'"
        case .characterSwap: return "E.g., 'A 3D Pixar-style explorer character'"
        case .fullTransformation: return "Describe the complete cinematic style, color grading, and subject transformation details..."
        }
    }
    
    public var promptIsRequired: Bool {
        switch self {
        case .clothingSwap: return false
        case .environmentSwap: return true
        case .characterSwap: return false
        case .fullTransformation: return true
        }
    }
}
