import SwiftUI

struct TaskDetailsView: View {
    let task: TaskItem
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text(task.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(task.details)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Изменить") {
                    onEdit()
                }
                .tint(.yellow)
            }
        }
    }
}
