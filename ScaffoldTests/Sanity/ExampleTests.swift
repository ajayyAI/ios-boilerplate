//
//  ExampleTests.swift
//  ScaffoldTests
//

import Testing
@testable import Scaffold

struct ExampleTests {
    @Test func `user entity maps to domain model`() {
        let model = UserModel(userEntity: UserEntity(email: "hello@example.com"))

        #expect(model.email == "hello@example.com")
    }

    @Test func `get user use case returns repository user`() async throws {
        let useCase = GetUserUseCase(
            userRepository: FakeUserRepository(result: .success(UserModel(email: "usecase@example.com"))),
        )

        let user = try await useCase.invoke()

        #expect(user.email == "usecase@example.com")
    }

    @MainActor
    @Test func `home view model refresh publishes loaded user`() async {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: FakeUserRepository(result: .success(UserModel(email: "home@example.com"))),
            ),
        )

        await viewModel.refresh()

        #expect(viewModel.state == .data(userEmailTitle: "home@example.com"))
    }

    @MainActor
    @Test func `home view model refresh publishes errors`() async {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: FakeUserRepository(result: .failure(ScaffoldError(message: "Failed"))),
            ),
        )

        await viewModel.refresh()

        #expect(viewModel.state == .failed(PresentableError(message: "Failed")))
    }

    @MainActor
    @Test func `home view model starts empty`() {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: FakeUserRepository(result: .success(UserModel(email: "a@b.com"))),
            ),
        )

        #expect(viewModel.state == .empty)
    }
}

private struct FakeUserRepository: UserRepositoryProtocol {
    let result: Result<UserModel, Error>

    func getUser() async throws -> UserModel {
        try result.get()
    }
}
