require 'socket'
require 'thread'

class TcpServer
  MAX_CONNECTIONS = 3
  attr_reader :connections

  def initialize(port)
    @server = TCPServer.new(port)
    @connections = []
    @mutex = Mutex.new
  end

  def start
    puts "Servidor rodando na porta #{@server.local_address.ip_port}..."

    loop do
      client = @server.accept

      if @connections.size < MAX_CONNECTIONS
        @mutex.synchronize { @connections << client }
        puts "Cliente conectado. Total de conexões: #{@connections.size}"

        Thread.new(client) do |socket|
          handle_client(socket)
        end
      else
        puts "Número máximo de conexões atingido. Informando ao cliente..."
        client.puts "RESPONSE|ERRO|CONEXAO|Número máximo de conexões atingido. Por favor, tente novamente mais tarde."
        client.close
      end
    end
  end

  private

  def handle_client(socket)
    begin
      loop do
        request = socket.gets
        break if request.nil?

        request = request.strip
        if request.start_with?("VALIDATE")
          process_request(request, socket)
        else
          socket.puts "RESPONSE|ERRO|COMANDO|Comando não reconhecido."
        end
      end
    ensure
      @mutex.synchronize { @connections.delete(socket) }
      socket.close
      puts "Cliente desconectado. Total de conexões: #{@connections.size}"
    end
  end

  def process_request(request, socket)
    tipo, numero = request.split('|')[1, 2] 

    if tipo.nil? || numero.nil?
      socket.puts "RESPONSE|ERRO|FORMATO|Formato da mensagem inválido."
      return
    end

    puts request
    case tipo.upcase
    when 'CPF'
      if numero.length == 11
        response = validate_cpf(numero) ? "RESPONSE|VALIDO|CPF|#{numero}" : "RESPONSE|INVALIDO|CPF|#{numero}"
      else
        response = "RESPONSE|ERRO|FORMATO|CPF deve ter 11 dígitos."
      end
    when 'CNPJ'
      if numero.length == 14
        response = validate_cnpj(numero) ? "RESPONSE|VALIDO|CNPJ|#{numero}" : "RESPONSE|INVALIDO|CNPJ|#{numero}"
      else
        response = "RESPONSE|ERRO|FORMATO|CNPJ deve ter 14 dígitos."
      end
    else
      response = "RESPONSE|ERRO|TIPO|Tipo não reconhecido."
    end

    socket.puts response
  end

  def validate_cpf(cpf)
    cpf.length == 11 
  end

  def validate_cnpj(cnpj)
    cnpj.length == 14 
  end
end
