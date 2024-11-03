import SwiftUI
import Combine

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    @State private var threadId: String?
    @State private var isLoading: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    private let api = UnwindAPI()
    
    var body: some View {
        VStack {
            chatScrollView
            messageInputField
            if isLoading {
                ProgressView("Waiting for response...")
                    .padding()
            }
        }
        .padding()
    }
    
    // MARK: - Chat Scroll View
    private var chatScrollView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: 250, alignment: .trailing)
                                    .multilineTextAlignment(.trailing)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .frame(maxWidth: 250, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                }
                .onChange(of: messages) { _, newMessages in
                    if let lastMessage = newMessages.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }

            }
        }
    }
    
    // MARK: - Message Input Field
    private var messageInputField: some View {
        HStack {
            TextField("How are you feeling today?", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled(true)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
            }
            .padding(.leading)
            .disabled(isLoading)
        }
    }
    
    // MARK: - Send Message Function
    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        
        let userMessage = ChatMessage(text: userInput, isUser: true)
        messages.append(userMessage)
        userInput = ""
        isLoading = true

        let sendMessagePublisher: AnyPublisher<Void, Error>
        
        if let threadId = threadId {
            // If thread already exists, just send a message
            sendMessagePublisher = api.sendMessagePublisher(threadId: threadId, content: userMessage.text)
        } else {
            // If no thread exists, create a new one and then send the message
            sendMessagePublisher = api.createThreadPublisher()
                .handleEvents(receiveOutput: { self.threadId = $0 })
                .flatMap { self.api.sendMessagePublisher(threadId: $0, content: userMessage.text) }
                .eraseToAnyPublisher()
        }

        // Send the message and start polling for the assistant's response
        sendMessagePublisher
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error sending message: \(error)")
                    self.messages.append(ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false))
                    self.isLoading = false
                }
            }, receiveValue: {
                print("Message sent successfully")
                self.startPollingForResponse()
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Start Polling for Assistant's Response
    private func startPollingForResponse() {
        guard let threadId = threadId else { return }
        
        api.pollUntilCompletion(threadId: threadId) { finalResponse in
            DispatchQueue.main.async {
                self.isLoading = false
                if let finalResponse = finalResponse {
                    let assistantMessage = ChatMessage(text: finalResponse, isUser: false)
                    self.messages.append(assistantMessage)
                } else {
                    self.messages.append(ChatMessage(text: "Failed to retrieve response.", isUser: false))
                }
            }
        }

    }
}

