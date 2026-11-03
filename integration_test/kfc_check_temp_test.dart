import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_year_project/main.dart' as app;
import 'package:final_year_project/presentation/screens/dashboard_screen.dart';
import 'package:final_year_project/presentation/screens/receipt_scan_screen.dart';
import 'package:final_year_project/presentation/state/expense_store.dart';
import 'package:final_year_project/presentation/widgets/finance_charts.dart';
import 'receipt_scan_test.dart' show FixturePicker;
void main(){
 IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 testWidgets('KFC receipt saves Food and converted RM and refreshes both charts', (t) async {
 await app.main();
 for(var i=0;i<750 && find.byType(DashboardScreen).evaluate().isEmpty;i++){
 await t.pump(const Duration(milliseconds:400));
 if(find.text('Get started').evaluate().isNotEmpty){await t.tap(find.text('Get started'));await t.pumpAndSettle();}
 }
 expect(find.byType(DashboardScreen),findsOneWidget,reason:'A signed-in account is required.');
 final ctx=t.element(find.byType(DashboardScreen));
 final store=ExpenseScope.of(ctx);
 final client=Supabase.instance.client;
 final uid=client.auth.currentUser!.id;
 final marker='KFC receipt test ${DateTime.now().microsecondsSinceEpoch}';
 final base=store.expense, income=store.income, budget=store.budget;
 final file=File('${Directory.systemTemp.path}/kfc-test.png');
 final bytes=await rootBundle.load('tmp/kfc_check/kfc.png');
 await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes,bytes.lengthInBytes));
 Future<void> tap(String label) async{
 final f=find.text(label).last;await Scrollable.ensureVisible(t.element(f),alignment:.5);await t.pumpAndSettle();await t.tap(f);await t.pumpAndSettle();
 }
 try{
 Navigator.of(ctx).push(MaterialPageRoute(builder:(_)=>ReceiptScanScreen(picker:FixturePicker([file.path]))));
 await t.pumpAndSettle();await tap('Choose photo');
 expect(find.text('Food'),findsOneWidget);
 final guide=t.widget<Text>(find.textContaining('Printed total: USD 15.88')).data!;
 final rate=double.parse(guide.split('1 USD = RM ').last.split('\n').first);
 final expected=(15.88*rate).toStringAsFixed(2);
 expect(t.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,expected);
 await t.enterText(find.byType(TextFormField).at(1),marker);
 await tap('Add expense');
 for(var i=0;i<100 && find.byType(ReceiptScanScreen).evaluate().isNotEmpty;i++){await t.pump(const Duration(milliseconds:300));}
 await t.pumpAndSettle();
 expect(find.byType(ReceiptScanScreen),findsNothing);
 final row=await client.from('transactions').select('amount, category_id, transaction_type').eq('user_id',uid).eq('description',marker).single();
 expect(row['transaction_type'],'expense');
 final cat=await client.from('categories').select('name').eq('id',row['category_id']).single();
 expect(cat['name'],'Food');
 expect(row['amount'],double.parse(expected));
 final after=base+double.parse(expected);
 await t.scrollUntilVisible(find.byType(CashFlowChart),200,scrollable:find.byType(Scrollable).first);
 final bar=t.widget<CashFlowChart>(find.byType(CashFlowChart));expect(bar.expense,closeTo(after,.001));expect(bar.income,income);
 expect(find.text('Recorded expenses · ${money(after)}'),findsOneWidget);
 await tap('Budget');
 await t.scrollUntilVisible(find.byType(BudgetChart),200,scrollable:find.byType(Scrollable).first);
 final ring=t.widget<BudgetChart>(find.byType(BudgetChart));expect(ring.spent,closeTo(after,.001));expect(ring.budget,budget);
 expect(find.text('${(100*after/budget).round()}%'),findsOneWidget);
 expect(t.takeException(),isNull);
 print('VERIFIED Food / $expected MYR / rate $rate / before $base / after $after / budget $budget');
 }finally{
 await client.from('transactions').delete().eq('user_id',uid).eq('description',marker);
 expect(await client.from('transactions').select('id').eq('user_id',uid).eq('description',marker),isEmpty);
 await file.delete();
 }
 });
}
