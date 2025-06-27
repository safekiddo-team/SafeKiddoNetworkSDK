

# 🚀 PolicyManagerClient & APIClient

## Spis treści

- [Opis](#opis)
- [Architektura](#architektura)
- [PolicyManagerClient](#policymanagerclient)
  - [Cechy](#cechy)
  - [Przykład użycia w ViewModel](#przykład-użycia-w-viewmodel)
- [APIClient](#apiclient)
  - [Cechy](#cechy-apiclient)
  - [Przykład użycia](#przykład-użycia-apiclient)
- [SSL Pinning](#ssl-pinning)
- [Debugowanie](#debugowanie)
- [Struktura projektu](#struktura-projektu)
- [Możliwości rozbudowy](#możliwości-rozbudowy)
- [Autor](#autor)

---

## 📌 Opis

To repozytorium zawiera dwa niezależne, profesjonalnie zaprojektowane klienty sieciowe w Swift:

- **`PolicyManagerClient`** – klient do zapytań polityk dostępowych, np. kontroli rodzicielskiej, filtrów treści czy systemów klasy Secure Web Gateway.
- **`APIClient`** – generyczny klient JSON dla dowolnych endpointów REST, wspierający wiele metod HTTP.

Obydwa klienty są gotowe do wdrożenia w aplikacjach iOS/macOS, obsługują **SSL Pinning** i zostały napisane w stylu czystego, czytelnego Swifta (Swift 5+).

---

## 🏛 Architektura

- Klienci oparci są o `URLSessionDelegate`, co pozwala im w pełni kontrolować sesję oraz łatwo wprowadzać SSL Pinning.
- Komunikacja oparta o `Codable` i `Result` dla prostszej obsługi sukcesów/błędów.
- Modele requestów i response są rozdzielone dla lepszej separacji warstw.
- Logika obsługi kodów HTTP jest wbudowana i pozwala reagować na 401/500 w sposób przyjazny dla użytkownika.

---

## 📌 PolicyManagerClient

### Cechy

✅ dynamiczny wybór endpointu (np. `check/policy` lub `check/url`)  
✅ łatwy do rozszerzenia w przyszłości  
✅ automatyczne kodowanie/dekodowanie JSON  
✅ SSL Pinning  
✅ delegat do weryfikacji certyfikatów  
✅ logowanie wysyłanych zapytań w konsoli  
✅ dopasowany do architektury MVVM

---

### Przykład użycia w ViewModel

```swift
import Foundation
import Combine

@MainActor
final class PolicyManagerViewModel: ObservableObject {
    @Published var urlToCheck: String = ""
    @Published var resultText: String = "-"
    @Published var isLoading: Bool = false

    private let client: PolicyManagerClient
    private var currentTask: URLSessionTask?

    init() {
        self.client = PolicyManagerClient(
            baseUrl: URL(string: "www.api.example.com")!,
            apiKey: "key",
            pinnedCertificateNames: ["myCert"],
            enableSSLPinning: true
        )
    }

    func check() {
        currentTask?.cancel()
        
        let cleanUrl = urlToCheck
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        
        guard !cleanUrl.isEmpty else {
            resultText = "Podaj adres URL"
            return
        }
        
        let req = PolicyRequest(
            requestId: UUID(),
            resource: cleanUrl,
            resourceType: .url,
            subject: "d7397cd3-a613-4179-8041-cacb9a68bda2",
            subjectType: .kid,
            apiKey: "PZLrjMfJxLLbpLrd",
            engines: ["default"],
            resultOperator: .and,
            logRequest: true,
            correlationId: ""
        )
        
        isLoading = true
        resultText = "Sprawdzam…"
        
        currentTask = client.checkPolicy(
            request: req,
            endpointType: .policy,
            timeoutMs: 3000
        ) { [weak self] result in
            guard let self else { return }
            Task { @MainActor in
                self.isLoading = false
                switch result {
                case .success(let resp):
                    let action = resp.result?.url?.action.rawValue ?? "brak decyzji"
                    self.resultText = "Serwer: \(action)"
                case .failure(let error):
                    self.resultText = "Błąd: \(error.localizedDescription)"
                    print("[PolicyManagerViewModel] Błąd: \(error)")
                }
            }
        }
    }
}

📌 APIClient

Drugi klient to APIClient, czyli uniwersalna warstwa do pracy z JSON dla dowolnych backendów.
Nie wymusza konkretnego formatu requestu — możesz przesyłać dowolne parametry jako [String: Any] i zdekodować odpowiedź do swojego typu Decodable.
Cechy APIClient

✅ obsługa GET/POST/PUT/DELETE
✅ dynamiczne nagłówki
✅ dynamiczne parametry
✅ prosty mechanizm dekodowania JSON
✅ automatyczna obsługa kodów błędów
✅ wbudowane SSL Pinning
✅ łatwy w testach jednostkowych
Przykład użycia

let apiClient = APIClient(
    baseURL: URL(string: "https://api.example.com")!,
    headers: ["x-app-key": "ABCDEF123456"],
    pinnedCertificateNames: ["myCert"],
    enableSSLPinning: true
)

apiClient.request(
    endpoint: "/users/me",
    method: .get
) { (result: Result<UserProfile, NetworkError>) in
    switch result {
    case .success(let profile):
        print("Zalogowany użytkownik: \(profile.name)")
    case .failure(let error):
        print("Błąd API: \(error)")
    }
}

🔐 SSL Pinning

Obydwaj klienci wykorzystują SSL Pinning na podstawie certyfikatu .cer dołączonego do aplikacji.

Aby włączyć pinning:

    Pobierz certyfikat serwera w formacie .cer.

    Dodaj plik do projektu w Xcode i zaznacz w Target Membership.

    W konstruktorze klienta wskaż nazwę pliku (bez rozszerzenia):

pinnedCertificateNames: ["myCert"]

    Jeśli certyfikat zostanie zmieniony po stronie serwera, pamiętaj o aktualizacji w bundlu aplikacji!
