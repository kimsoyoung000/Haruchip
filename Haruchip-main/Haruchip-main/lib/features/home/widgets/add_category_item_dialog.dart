/// ?섏쐞 ?명솚???ъ썙???뚯씪.
///
/// 湲곗〈 肄붾뱶踰좎씠???꾩껜?먯꽌 [showAddCategoryItemDialog]瑜??꾪룷?명븯??/// 肄쒖궗?댄듃?ㅼ씠 而댄뙆???먮윭 ?놁씠 ?숈옉?섎룄濡? ??諛뷀??쒗듃濡??⑥닚
/// ?ъ썙?⑺븳?? ??肄붾뱶?먯꽌??[showAddEventBottomSheet]瑜?吏곸젒 ?ъ슜?쒕떎.
library;

export '../../../features/shared/widgets/add_event_bottom_sheet.dart'
    show showAddEventBottomSheet;

import 'package:flutter/material.dart';

import '../../shared/widgets/add_event_bottom_sheet.dart';

/// [showAddEventBottomSheet]濡??ъ썙?⑺븯???섏쐞 ?명솚 ?섑띁.
///
/// ??肄붾뱶?먯꽌??[showAddEventBottomSheet]瑜?諛붾줈 ?몄텧?섏꽭??
Future<void> showAddCategoryItemDialog(
  BuildContext context, {
  required String categoryKey,
  String? categoryInstanceId,
  DateTime? initialDate,
}) =>
    showAddEventBottomSheet(
      context,
      categoryKey: categoryKey,
      categoryInstanceId: categoryInstanceId,
      initialDate: initialDate,
    );
