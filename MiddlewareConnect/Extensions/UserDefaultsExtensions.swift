import Foundation

// UserDefaults extensions for convenience
public extension UserDefaults {
    var apiFeatureToggles: ApiFeatureToggles? {
        get {
            guard let data = data(forKey: "api_feature_toggles") else { return nil }
            return try? JSONDecoder().decode(ApiFeatureToggles.self, from: data)
        }
        set {
            guard let newValue = newValue, let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "api_feature_toggles")
        }
    }
    
    var apiUsageStats: ApiUsageStats? {
        get {
            guard let data = data(forKey: "api_usage_stats") else { return nil }
            return try? JSONDecoder().decode(ApiUsageStats.self, from: data)
        }
        set {
            guard let newValue = newValue, let data = try? JSONEncoder().encode(newValue) else { return }
            set(data, forKey: "api_usage_stats")
        }
    }
}
