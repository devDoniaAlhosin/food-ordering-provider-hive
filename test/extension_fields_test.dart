import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:w10_s20_food_ordering_provider_hive/extensions/text_form_field_extensions.dart";

void main() {
  testWidgets("extension fields build", (tester) async {
    final email = TextEditingController();
    final password = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: Column(
              children: [
                AppTextFormField.email(controller: email),
                AppTextFormField.password(controller: password),
                AppTextFormField.fullName(controller: TextEditingController()),
                AppTextFormField.phone(controller: TextEditingController()),
                AppTextFormField.address(controller: TextEditingController()),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.byType(TextFormField), findsNWidgets(5));
  });
}
