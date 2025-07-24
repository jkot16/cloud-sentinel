from dashboard.app import app

def test_status_route_returns_200():
    with app.test_client() as client:
        response = client.get("/status")
        assert response.status_code == 200
