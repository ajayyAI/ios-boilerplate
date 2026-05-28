//
//  ExampleTests.swift
//  TemplateAppTests
//
//

@testable import TemplateApp
import Testing

struct ExampleTests {
    @Test func userEntityMapsToDomainModel() {
        let model = UserModel(userEntity: UserEntity(email: "hello@example.com"))

        #expect(model.email == "hello@example.com")
    }

    @Test func getUserUseCaseReturnsRepositoryUser() async throws {
        let useCase = GetUserUseCase(
            userRepository: FakeUserRepository(result: .success(UserModel(email: "usecase@example.com")))
        )

        let user = try await useCase.invoke()

        #expect(user.email == "usecase@example.com")
    }

    @MainActor
    @Test func homeViewModelRefreshPublishesLoadedUser() async {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: FakeUserRepository(result: .success(UserModel(email: "home@example.com")))
            )
        )

        await viewModel.refresh()

        guard case let .data(userEmailTitle) = viewModel.state else {
            Issue.record("Expected loaded data state")
            return
        }

        #expect(userEmailTitle == "home@example.com")
    }

    @MainActor
    @Test func homeViewModelRefreshPublishesErrors() async {
        let viewModel = HomeViewModel(
            getUser: GetUserUseCase(
                userRepository: FakeUserRepository(result: .failure(TemplateAppError(message: "Failed")))
            )
        )

        await viewModel.refresh()

        guard case let .error(error) = viewModel.state else {
            Issue.record("Expected error state")
            return
        }

        #expect(error.localizedDescription == "Failed")
    }
}

private struct FakeUserRepository: UserRepositoryProtocol {
    let result: Result<UserModel, Error>

    func getUser() async throws -> UserModel {
        try result.get()
    }
}
