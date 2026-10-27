# OneDrive: recuperar arquivos e voltar ao armazenamento local

Guia prático para diagnosticar o OneDrive no Windows, baixar arquivos que ainda estão somente na nuvem e deixar de sincronizar pastas com segurança.

## O que o OneDrive faz

O OneDrive sincroniza arquivos entre o computador e a nuvem. Também pode redirecionar pastas conhecidas do Windows, como Área de Trabalho, Documentos e Imagens, para dentro da pasta do OneDrive. O Windows funciona sem o aplicativo; arquivos que estão somente na nuvem precisam ser baixados antes de o aplicativo ser removido. Desinstalar o aplicativo não apaga os arquivos que já estão na conta OneDrive online.

## Antes de começar

- Salve o trabalho aberto e feche programas que estejam usando arquivos dentro do OneDrive.
- Confirme que há espaço livre suficiente para baixar os arquivos importantes.
- Não apague nem mova arquivos enquanto o OneDrive ainda estiver conectado: a remoção pode sincronizar e apagar a cópia da nuvem.
- Se quiser manter uma cópia na nuvem, baixe os arquivos e depois desvincule o computador. Não escolha uma opção que remova os arquivos do OneDrive online.

## 1. Diagnosticar memória, disco e pastas redirecionadas

Abra o PowerShell. Os comandos abaixo apenas consultam informações:

```powershell
# Uso de memória e CPU dos processos
Get-Process OneDrive, explorer -ErrorAction SilentlyContinue |
  Select-Object ProcessName, Id, CPU,
    @{Name='MemoriaGB'; Expression={[math]::Round($_.WorkingSet64 / 1GB, 2)}}

# Espaço livre no C:
Get-PSDrive C | Select-Object Name,
  @{Name='LivreGB'; Expression={[math]::Round($_.Free / 1GB, 1)}},
  @{Name='UsadoGB'; Expression={[math]::Round($_.Used / 1GB, 1)}}

# Caminhos das pastas conhecidas do Windows
$k = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
[pscustomobject]@{
  AreaDeTrabalho = $k.Desktop
  Documentos     = $k.Personal
  Imagens        = $k.'My Pictures'
}
```

Se `Desktop`, `Personal` ou `My Pictures` apontarem para `$env:OneDrive`, essas pastas estão redirecionadas para o OneDrive.

O script [`scripts/Diagnostico-OneDrive.ps1`](scripts/Diagnostico-OneDrive.ps1) reúne essas consultas em um relatório local, sem alterar configurações nem arquivos.

## 2. Identificar arquivos somente na nuvem

No Explorador de Arquivos, observe o ícone de status ao lado dos arquivos:

- Nuvem azul: o arquivo está somente online.
- Marca verde: o arquivo está baixado e disponível localmente.
- Círculo verde com marca branca: o arquivo foi baixado e marcado para ficar sempre no dispositivo.

Para verificar um arquivo específico pelo PowerShell:

```powershell
attrib "$env:OneDrive\Documentos\nome-do-arquivo.ext"
```

No resultado, `O` indica o atributo Offline e `U` indica que o arquivo não está fixado. Para solicitar que um arquivo seja baixado e fique sempre disponível:

```powershell
attrib +p "$env:OneDrive\Documentos\nome-do-arquivo.ext"
```

Para uma pasta importante, clique com o botão direito no Explorador e escolha **Sempre manter neste dispositivo**. Aguarde a sincronização e confirme que os arquivos importantes abrirão sem internet. Fixar um arquivo online faz o aplicativo baixar seu conteúdo; os estados e atributos são descritos na [documentação da Microsoft](https://learn.microsoft.com/pt-br/sharepoint/files-on-demand-windows).

## 3. Se o OneDrive estiver consumindo muita memória

Primeiro confira a memória com o comando da seção 1 e salve o trabalho aberto. Para encerrar o OneDrive travado:

```powershell
Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
```

Isso encerra o aplicativo; não apaga arquivos. Para reiniciar o Explorador quando Início ou Este Computador ficarem presos em “Trabalhando nisso...”:

```powershell
Stop-Process -Name explorer -Force
Start-Process explorer.exe
```

As janelas do Explorador podem fechar e reabrir. O desktop e a barra de tarefas também podem piscar durante o reinício.

## 4. Preparar os arquivos para uso local

1. Baixe os arquivos importantes com **Sempre manter neste dispositivo**.
2. Aguarde a conclusão e abra uma amostra de cada pasta importante. Não remova o OneDrive enquanto arquivos necessários ainda estiverem somente online.
3. Se preferir fazer uma cópia local separada, use um destino com espaço suficiente. Este exemplo copia Documentos sem apagar a origem:

```powershell
$origem = Join-Path $env:OneDrive 'Documentos'
$destino = Join-Path $env:USERPROFILE 'Documentos locais do OneDrive'
robocopy $origem $destino /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:2
```

O Robocopy retorna códigos de saída de `0` a `7` para cópias sem falha fatal; códigos `8` ou maiores indicam falhas que precisam ser revistas. Confira os arquivos no destino antes de apagar qualquer coisa. Repita para `Desktop` e `Pictures` se necessário.

## 5. Desvincular e desinstalar

1. No ícone de nuvem do OneDrive perto do relógio, abra **Ajuda e Configurações > Configurações > Conta > Desvincular este computador**.
2. Depois de desvincular, confira se as cópias baixadas continuam acessíveis.
3. No Windows, abra **Configurações > Aplicativos > Aplicativos instalados > Microsoft OneDrive > Desinstalar**.
4. Se quiser, mova as pastas locais para os caminhos padrão do perfil (`%USERPROFILE%\Desktop`, `%USERPROFILE%\Documents` e `%USERPROFILE%\Pictures`) e configure esses caminhos nas propriedades de Local das pastas.

A Microsoft informa que desvincular ou desinstalar o aplicativo não apaga os arquivos da conta online; eles permanecem acessíveis pelo OneDrive na Web. Veja [como desvincular ou desinstalar](https://support.microsoft.com/en-us/onedrive/turn-off-disable-or-uninstall-onedrive) e [como parar o backup de pastas](https://support.microsoft.com/en-us/onedrive/back-up-your-folders-with-onedrive).

> Ao parar o backup de uma pasta, leia com cuidado as opções apresentadas: uma delas pode remover os arquivos da nuvem. Se você quer manter a cópia online, prefira desvincular o PC depois de confirmar a cópia local.

## 6. Verificar o resultado

```powershell
Get-Process OneDrive -ErrorAction SilentlyContinue
Get-PSDrive C | Select-Object Name,
  @{Name='LivreGB'; Expression={[math]::Round($_.Free / 1GB, 1)}}
```

O primeiro comando não deve listar nenhum processo OneDrive depois da desinstalação. Abra Início, Este Computador, Documentos, Área de Trabalho e Imagens para confirmar que o Windows está usando os caminhos locais desejados.

## Referências

- [Microsoft: arquivos sob demanda no Windows](https://learn.microsoft.com/pt-br/sharepoint/files-on-demand-windows)
- [Microsoft: desvincular, ocultar ou desinstalar o OneDrive](https://support.microsoft.com/en-us/onedrive/turn-off-disable-or-uninstall-onedrive)
- [Microsoft: fazer backup das pastas do PC](https://support.microsoft.com/en-us/onedrive/back-up-your-folders-with-onedrive)

## Licença

MIT. Consulte [`LICENSE`](LICENSE).
