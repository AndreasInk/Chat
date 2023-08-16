//
//  ConversationsView.swift
//  ChatFirestoreExample
//
//  Created by Alisa Mylnikova on 03.07.2023.
//

import SwiftUI
import ActivityIndicatorView

struct ConversationsView: View {

    @ObservedObject var dataStorage = DataStorageManager.shared
    @StateObject var viewModel = ConversationsViewModel()

    @State var showUsersList = false
    @State var navPath = NavigationPath()

    var body: some View {
        ZStack {
            content

            if viewModel.showActivityIndicator {
                ActivityIndicator()
            }
        }
        .task {
            viewModel.subscribeToUpdates()
        }
    }

    var content: some View {
        NavigationStack(path: $navPath) {
            SearchField(text: $viewModel.searchText)
                .padding(.horizontal, 12)

            List(viewModel.filteredConversations) { conversation in
                HStack {
                    if let url = conversation.pictureURL {
                        AvatarView(url: url, size: 56)
                    } else {
                        HStack(spacing: -30) {
                            ForEach(conversation.notMeUsers) { user in
                                AvatarView(url: user.avatarURL, size: 56)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.displayTitle)
                            .font(17, .black, .medium)

                        if let latest = conversation.latestMessage {
                            HStack(alignment: .bottom, spacing: 0) {
                                if !conversation.isPrivate {
                                    Text("\(latest.senderName): ")
                                        .font(15, .exampleTetriaryText)
                                } else if latest.isMyMessage {
                                    Text("You: ")
                                        .font(15, .exampleTetriaryText)
                                }

                                if let text = latest.text {
                                    Text(text)
                                        .lineLimit(1)
                                        .font(15, .exampleSecondaryText)
                                }
                                if let subtext = latest.subtext {
                                    Text(subtext)
                                        .font(15, .exampleBlue)
                                }
                                if let date = latest.createdAt?.timeAgoFormat() {
                                    Text(" · \(date)")
                                        .font(13, .exampleTetriaryText)
                                }
                            }
                        }
                    }
                }
                .background(
                    NavigationLink("", value: conversation)
                        .opacity(0)
                )
                .listRowSeparator(.hidden)
            }
            .refreshable {
                await viewModel.getData()
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Conversation.self) { conversation in
                ConversationView(viewModel: ConversationViewModel(conversation: conversation))
            }
            .navigationDestination(for: User.self) { user in
                ConversationView(viewModel: ConversationViewModel(user: user))
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showUsersList = true
                    } label: {
                        Image(.newChat)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Logout") {
                        SessionManager.shared.logout()
                    }
                }
            }
        }
        .sheet(isPresented: $showUsersList) {
            UsersView(viewModel: UsersViewModel(), isPresented: $showUsersList, navPath: $navPath)
        }
    }
}