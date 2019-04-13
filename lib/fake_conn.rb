class FakeConn
  
  FakeResponse = Struct.new(:status, :body)

  def get(path)
    FakeResponse.new(200, test_data)
  end

  def test_data
    JSON.dump(
      [
        { login: 'one' },
        { login: 'two' },
        { login: 'three' }
      ]
    )
  end
end
