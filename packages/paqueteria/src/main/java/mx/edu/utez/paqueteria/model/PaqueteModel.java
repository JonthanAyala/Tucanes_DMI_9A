package mx.edu.utez.paqueteria.model;

import com.google.cloud.Timestamp;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PaqueteModel {
    private String id;
    private String destinatario;

    // Direcciones detalladas (origen y destino)
    // Campos: calle, numero, cp, colonia, municipio, estado, referencias, telefono,
    // lat, lng
    private Map<String, Object> origen;
    private Map<String, Object> destino;

    private Double peso;
    private String estado; // pendiente, asignado, en_transito, entregado
    private String clienteId;
    private String repartidorId;
    private String fotoUrl;
    private Timestamp fechaCreacion;
    private String codigoQR;

    // Ubicaciones de escaneo
    // Campos: lat, lng, timestamp
    private Map<String, Object> ubicacionRecoleccion;
    private Map<String, Object> ubicacionEntrega;

    // Getters y Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getDestinatario() {
        return destinatario;
    }

    public void setDestinatario(String destinatario) {
        this.destinatario = destinatario;
    }

    public Map<String, Object> getOrigen() {
        return origen;
    }

    public void setOrigen(Map<String, Object> origen) {
        this.origen = origen;
    }

    public Map<String, Object> getDestino() {
        return destino;
    }

    public void setDestino(Map<String, Object> destino) {
        this.destino = destino;
    }

    public Double getPeso() {
        return peso;
    }

    public void setPeso(Double peso) {
        this.peso = peso;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getClienteId() {
        return clienteId;
    }

    public void setClienteId(String clienteId) {
        this.clienteId = clienteId;
    }

    public String getRepartidorId() {
        return repartidorId;
    }

    public void setRepartidorId(String repartidorId) {
        this.repartidorId = repartidorId;
    }

    public String getFotoUrl() {
        return fotoUrl;
    }

    public void setFotoUrl(String fotoUrl) {
        this.fotoUrl = fotoUrl;
    }

    public Timestamp getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(Timestamp fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }

    public String getCodigoQR() {
        return codigoQR;
    }

    public void setCodigoQR(String codigoQR) {
        this.codigoQR = codigoQR;
    }

    public Map<String, Object> getUbicacionRecoleccion() {
        return ubicacionRecoleccion;
    }

    public void setUbicacionRecoleccion(Map<String, Object> ubicacionRecoleccion) {
        this.ubicacionRecoleccion = ubicacionRecoleccion;
    }

    public Map<String, Object> getUbicacionEntrega() {
        return ubicacionEntrega;
    }

    public void setUbicacionEntrega(Map<String, Object> ubicacionEntrega) {
        this.ubicacionEntrega = ubicacionEntrega;
    }

    /**
     * Método helper para obtener dirección legible desde el mapa destino
     * Útil para notificaciones y logs
     */
    public String getDireccionFormateada() {
        if (destino == null)
            return "";

        StringBuilder sb = new StringBuilder();
        if (destino.get("calle") != null)
            sb.append(destino.get("calle"));
        if (destino.get("numero") != null)
            sb.append(" ").append(destino.get("numero"));
        if (destino.get("colonia") != null)
            sb.append(", ").append(destino.get("colonia"));
        if (destino.get("municipio") != null)
            sb.append(", ").append(destino.get("municipio"));

        return sb.toString().trim();
    }
}
