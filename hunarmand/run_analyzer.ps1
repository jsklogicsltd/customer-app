try {
    Write-Output "Running flutter analyze..."
    flutter analyze --machine > "analyze_output.txt" 2>&1
    Write-Output "Done."
} catch {
    Write-Error $_
}
