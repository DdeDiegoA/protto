# protto skills
# ponytail: find SKILL.md up to depth 3, dedupe by name.

list_skills() {
  local found=0
  for d in "${SKILL_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    found=1
    echo "=== $d ==="
    find "$d" -maxdepth 3 -type f -name 'SKILL.md' | sort | while read -r skill; do
      printf '  [ ] %s  (%s)\n' "$(basename "$(dirname "$skill")")" "$skill"
    done
  done
  if [[ $found -eq 0 ]]; then
    echo "No skill directories found in: ${SKILL_DIRS[*]}"
  fi
}

collect_skills() {
  local skills=""
  for d in "${SKILL_DIRS[@]}"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r skill; do
      skills+=$(basename "$(dirname "$skill")")$'\n'
    done < <(find "$d" -maxdepth 3 -type f -name 'SKILL.md' 2>/dev/null)
  done
  [[ -n "$skills" ]] && printf '%s' "$skills" | sort -u | grep -v '^$' || true
}

# ponytail: one case statement, no config file, no DB.
# maps known skill names to post-setup suggestions for the agent.
skill_suggestion() {
  case "$1" in
    speckit-specify)          echo "Usa /speckit-specify para crear el spec.md del proyecto" ;;
    speckit-plan)             echo "Usa /speckit-plan para generar el plan de implementación" ;;
    speckit-clarify)          echo "Usa /speckit-clarify si el spec tiene ambigüedades" ;;
    grill-me)                 echo "Valida el plan con /grill-me antes de implementar" ;;
    design-taste-frontend)    echo "Define dirección visual antes de generar UI" ;;
    "design-taste-frontend-v1") echo "Define dirección visual (v1) antes de generar UI" ;;
    llm-council)              echo "Usa llm-council para validar decisiones de arquitectura" ;;
    proyecto-lean)            echo "Usa proyecto-lean como orquestador para proyectos multi-fase" ;;
    vault-governance)         echo "Captura decisiones en el vault con vault-governance" ;;
    graphify)                 echo "Genera el knowledge graph del proyecto: ejecuta al inicio y tras cada tarea" ;;
    requesting-code-review)   echo "Configura code review pre-commit con requesting-code-review" ;;
    agent-delegation)         echo "Delega tareas aisladas con agent-delegation" ;;
    open-design-integration)  echo "Integra Open Design para diseño visual iterativo" ;;
    business-opportunity)     echo "Valida oportunidad de negocio con business-opportunity" ;;
    plan)                     echo "Genera un plan de acción detallado con /plan" ;;
    architecture-diagram)     echo "Diagrama la arquitectura con architecture-diagram" ;;
    excalidraw)               echo "Crea wireframes con excalidraw" ;;
    naming)                   echo "Usa naming para validar nombres de proyecto/módulos" ;;
    youtube-content)          echo "Investiga contenido relevante en YouTube con youtube-content" ;;
    arxiv)                    echo "Busca papers relevantes en arxiv" ;;
    *)                        return 1 ;;
  esac
}

suggest_all() {
  local skills
  skills=$(collect_skills)
  [[ -z "$skills" ]] && return
  local found=0
  {
    echo ""
    echo "## Suggested Post-Setup Workflow"
    echo ""
    while IFS= read -r name; do
      local sug
      sug=$(skill_suggestion "$name" 2>/dev/null) || continue
      echo "- **\`$name\`**: $sug"
      found=1
    done <<< "$skills"
    if [[ $found -eq 0 ]]; then
      echo "No known skills with post-setup suggestions detected."
    fi
  }
}
