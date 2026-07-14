import SwiftUI

struct FoodDataSourceView: View {
    @Environment(\.dismiss) private var dismiss

    let food: FoodReference

    var body: some View {
        NavigationStack {
            List {
                Section("数据性质") {
                    LabeledContent("食物") {
                        Text(food.name)
                    }
                    LabeledContent("标记") {
                        Text(food.source.badgeText)
                            .fontWeight(.semibold)
                    }
                }

                Section("来源详情") {
                    LabeledContent("来源") {
                        Text(food.source.name)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("营养基准") {
                        Text(food.source.specification)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("核验日期") {
                        Text(
                            food.source.verifiedAt,
                            format: .dateTime.year().month().day()
                        )
                    }
                    if let url = food.source.url {
                        Link(destination: url) {
                            Label("打开来源网页", systemImage: "safari")
                        }
                    }
                }

                if food.source.evidenceLevel == .nonOfficial {
                    Section("使用提示") {
                        Text("非官方数据基于配方估算、样本合并或用户提供，仅供日常营养记录参考，不用于医疗诊断。")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("数据说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
