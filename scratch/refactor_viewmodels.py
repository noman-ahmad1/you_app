import os
import re

service_map = {
    'user': 'UserService',
    'volunteer_info': 'VolunteerService',
    'mood': 'MoodService',
    'journal': 'JournalService',
    'chatRequest': 'ChatRequestService',
    'chat': 'ChatService',
    'community': 'CommunityService',
}

for root, _, files in os.walk('lib'):
    for filename in files:
        if filename.endswith('viewmodel.dart'):
            filepath = os.path.join(root, filename)
            with open(filepath, 'r') as f:
                content = f.read()

            new_content = content
            
            # Remove the old _firestoreService declaration
            new_content = re.sub(r'^\s*final\s+_firestoreService\s*=\s*locator<FirestoreService>\(\);\n', '', new_content, flags=re.MULTILINE)
            
            # Replace usages
            used_services = set()
            for prop, service in service_map.items():
                pattern = f'_firestoreService\.{prop}'
                if re.search(pattern, new_content):
                    used_services.add(service)
                    new_content = re.sub(pattern, f'locator<{service}>()', new_content)
            
            # Ensure imports are present for the used services
            for service in used_services:
                import_stmt = f"import 'package:you_app/services/{service.replace('Service', '_service').lower()}';"
                # Hacky un-camel-case for standard files: User_service -> user_service
                if service == 'ChatRequestService':
                    import_str = "import 'package:you_app/services/chat_request_service.dart';"
                else:
                    snake_case = re.sub(r'(?<!^)(?=[A-Z])', '_', service).lower()
                    import_str = f"import 'package:you_app/services/{snake_case}.dart';"
                
                if import_str not in new_content:
                    # insert after the last import
                    imports = re.findall(r"^import\s+'.+';\n", new_content, flags=re.MULTILINE)
                    if imports:
                        last_import = imports[-1]
                        new_content = new_content.replace(last_import, last_import + import_str + "\n")

            if new_content != content:
                print(f"Updated {filepath}")
                with open(filepath, 'w') as f:
                    f.write(new_content)

