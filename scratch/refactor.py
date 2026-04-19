import os
import glob

replacements = {
    "locator<FirestoreService>().user": "locator<UserService>()",
    "locator<FirestoreService>().volunteer_info": "locator<VolunteerService>()",
    "locator<FirestoreService>().mood": "locator<MoodService>()",
    "locator<FirestoreService>().journal": "locator<JournalService>()",
    "locator<FirestoreService>().chatRequest": "locator<ChatRequestService>()",
    "locator<FirestoreService>().chat": "locator<ChatService>()",
    "locator<FirestoreService>().community": "locator<CommunityService>()",
    "package:you_app/services/firestore_service.dart": "package:you_app/services/user_service.dart';\nimport 'package:you_app/services/volunteer_service.dart';\nimport 'package:you_app/services/mood_service.dart';\nimport 'package:you_app/services/journal_service.dart';\nimport 'package:you_app/services/chat_service.dart';\nimport 'package:you_app/services/chat_request_service.dart';\nimport 'package:you_app/services/community_service.dart"
}

for root, _, files in os.walk('lib'):
    for filename in files:
        if filename.endswith('.dart'):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r') as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements.items():
                new_content = new_content.replace(old, new)
                
            if new_content != content:
                print(f"Updated {filepath}")
                with open(filepath, 'w') as f:
                    f.write(new_content)
