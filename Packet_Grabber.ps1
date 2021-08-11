Write-Host `n
#Listening interface address 
$IP_ADDRESS = "192.168.x.x"

for ($temp = 0; $temp -lt 1; $temp--)
{

    try{
        $socket = New-object System.Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork,[Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Unspecified)
        $socket.bind((New-Object System.Net.IPEndPoint([Net.IPAddress]$IP_ADDRESS, 0)))
        $socket.SetSocketOption([Net.Sockets.SocketOptionLevel]::IP, [Net.Sockets.SocketOptionName]::HeaderIncluded, $true)
        $null = $socket.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), [BitConverter]::GetBytes([int]0))

        $buffer = New-Object Byte[]($socket.ReceiveBufferSize)

        $r = $socket.Receive($buffer, 0, $buffer.Length, 0)
        
        $new_buff = New-Object Byte[] ($r)
        for ($j = 0; $j -lt $r; $j++){$new_buff[$j] = $buffer[$j]}       

        switch($new_buff[9])
        {
            1  {[string]$protocol = "ICMP"; [string]$data = $new_buff[20..($new_buff.Length)]}
            2  {[string]$protocol = "IGMP"}
            6  {[string]$protocol = "TCP"; [string]$data = $new_buff[39..($new_buff.Length)]}
            17 {[string]$protocol = "UDP"; [string]$data = $new_buff[27..($new_buff.Length)]}
            default {[string]$protocol = "ADD: " + $new_buff[9].toString(); [string]$data = ""}
        }

        [string]$src_ip = $new_buff[12].toString() + '.' + $new_buff[13].toString() + '.' + $new_buff[14].tOString() + '.' + $new_buff[15].toString()
        [string]$dst_ip = $new_buff[16].toString() + '.' + $new_buff[17].toString() + '.' + $new_buff[18].tOString() + '.' + $new_buff[19].toString()
        [string]$src_port = ($new_buff[20] * 256 + $new_buff[21]).toString()
        [string]$dst_port = ($new_buff[22] * 256 + $new_buff[23]).toString()

        [string]$output_data = ""

        forEach ($d in $data.Split(" "))
        {
            $output_data += [system.text.encoding]::GetEncoding("shift_jis").GetString($d)
        }
        
        Write-Host [$protocol] -ForegroundColor Green -NoNewline
        Write-Host $src_ip`: -ForegroundColor Red -NoNewline
        Write-Host $src_port -ForegroundColor Yellow -NoNewline
        Write-Host --> -ForegroundColor White -NoNewline 
        Write-Host $dst_ip`: -ForegroundColor Red -NoNewline
        Write-Host $dst_port -ForegroundColor Yellow -NoNewline
        Write-Host `{ $output_data.ToString() `} -ForegroundColor Green} 

    catch [System.Exception]{
        Write-Host $_; 
    }
    
    finally {
        $socket.Close();
    }
}
