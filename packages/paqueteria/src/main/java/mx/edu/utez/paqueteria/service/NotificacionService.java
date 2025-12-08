package mx.edu.utez.paqueteria.service;

import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import lombok.RequiredArgsConstructor;
import mx.edu.utez.paqueteria.dto.PaqueteEventDTO;
import mx.edu.utez.paqueteria.exception.NotificacionException;
import mx.edu.utez.paqueteria.exception.RecursoNoEncontradoException;
import mx.edu.utez.paqueteria.model.PaqueteModel;
import mx.edu.utez.paqueteria.model.UsuarioModel;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

/**
 * Servicio de notificaciones de paquetería
 * Maneja 4 casos: Nuevo pedido, Pedido asignado, Pedido tomado, Pedido
 * entregado
 * Recupera información faltante directamente de Firestore.
 * 
 * @author JonthanAyala
 */
@Service
public class NotificacionService {

    private final FirebaseMessagingService fcmService;

    public NotificacionService(FirebaseMessagingService fcmService) {
        this.fcmService = fcmService;
    }

    /**
     * CASO 1: Notificar al cliente que su paquete fue tomado por un repartidor
     */
    public void notificarPedidoTomado(PaqueteEventDTO evento) {
        try {
            // 1. Completar datos faltantes (Nombre del repartidor)
            if (evento.getRepartidorNombre() == null || evento.getRepartidorNombre().isEmpty()) {
                UsuarioModel repartidor = obtenerUsuario(evento.getRepartidorId());
                if (repartidor != null) {
                    evento.setRepartidorNombre(repartidor.getNombre());
                } else {
                    throw new RecursoNoEncontradoException(
                            "Repartidor no encontrado con ID: " + evento.getRepartidorId());
                }
            }

            // 2. Obtener clienteId si falta
            if (evento.getClienteId() == null || evento.getClienteId().isEmpty()) {
                PaqueteModel paquete = obtenerPaquete(evento.getPaqueteId());
                if (paquete != null) {
                    evento.setClienteId(paquete.getClienteId());
                } else {
                    throw new RecursoNoEncontradoException("Paquete no encontrado con ID: " + evento.getPaqueteId());
                }
            }

            System.out.println("Notificando pedido tomado - Paquete: " + evento.getPaqueteId() + ", Repartidor: "
                    + evento.getRepartidorNombre());

            // 3. Obtener cliente para su token
            UsuarioModel cliente = obtenerUsuario(evento.getClienteId());

            if (cliente == null) {
                throw new RecursoNoEncontradoException("Cliente no encontrado con ID: " + evento.getClienteId());
            }

            Map<String, String> data = new HashMap<>();
            data.put("tipo", "asignacion");
            data.put("paqueteId", evento.getPaqueteId());
            data.put("repartidorId", evento.getRepartidorId());
            data.put("userId", evento.getClienteId());

            String titulo = "🚚 Paquete en camino";
            String mensaje = String.format("%s tomó tu paquete y está en camino", evento.getRepartidorNombre());

            // Guardar en Firestore (Historial)
            guardarNotificacionEnFirestore(evento.getClienteId(), titulo, mensaje, "asignacion", data);

            // Enviar Push si tiene token
            if (cliente.getFcmToken() != null && !cliente.getFcmToken().isEmpty()) {
                fcmService.enviarNotificacion(cliente.getFcmToken(), titulo, mensaje, data);
                System.out.println("Notificación enviada al cliente: " + evento.getClienteId());
            } else {
                System.out.println(
                        "Cliente " + evento.getClienteId() + " no tiene token FCM, solo se guardó en historial");
            }

        } catch (RecursoNoEncontradoException e) {
            throw e; // Re-lanzar para que el controlador la capture
        } catch (Exception e) {
            System.out.println("Error al notificar pedido tomado: " + e.getMessage());
            e.printStackTrace();
            throw new NotificacionException("Error interno al procesar notificación de pedido tomado", e);
        }
    }

    /**
     * CASO 2: Notificar a todos los repartidores sobre un nuevo pedido disponible
     */
    public void notificarNuevoPedido(PaqueteEventDTO evento) {
        try {
            // 1. Completar datos del paquete si faltan
            if (evento.getDestinatario() == null || evento.getDireccion() == null) {
                PaqueteModel paquete = obtenerPaquete(evento.getPaqueteId());
                if (paquete != null) {
                    evento.setDestinatario(paquete.getDestinatario());
                    // Usar dirección formateada desde el mapa destino
                    evento.setDireccion(paquete.getDireccionFormateada());
                } else {
                    throw new RecursoNoEncontradoException("Paquete no encontrado con ID: " + evento.getPaqueteId());
                }
            }

            System.out.println("Notificando nuevo pedido - Paquete: " + evento.getPaqueteId() + ", Destinatario: "
                    + evento.getDestinatario());

            // 2. Obtener repartidores
            Map<String, String> repartidoresTokens = obtenerRepartidoresConTokens();

            if (!repartidoresTokens.isEmpty()) {
                String titulo = "📦 Nuevo paquete disponible";
                String mensaje = String.format("Paquete para %s - %s", evento.getDestinatario(), evento.getDireccion());

                for (Map.Entry<String, String> entry : repartidoresTokens.entrySet()) {
                    String repartidorId = entry.getKey();
                    String token = entry.getValue();

                    Map<String, String> data = new HashMap<>();
                    data.put("tipo", "paquete");
                    data.put("paqueteId", evento.getPaqueteId());
                    data.put("destinatario", evento.getDestinatario());
                    data.put("direccion", evento.getDireccion());
                    data.put("userId", repartidorId);

                    // Guardar en Firestore (Historial)
                    guardarNotificacionEnFirestore(repartidorId, titulo, mensaje, "paquete", data);

                    // Enviar Push
                    fcmService.enviarNotificacion(token, titulo, mensaje, data);
                }
                System.out.println("Notificaciones enviadas a " + repartidoresTokens.size() + " repartidores");
            } else {
                System.out.println("No hay repartidores disponibles");
            }
        } catch (RecursoNoEncontradoException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("Error al notificar nuevo pedido: " + e.getMessage());
            e.printStackTrace();
            throw new NotificacionException("Error interno al procesar notificación de nuevo pedido", e);
        }
    }

    /**
     * CASO 3: Notificar al cliente que su paquete fue asignado a un repartidor
     */
    public void notificarPedidoAsignado(PaqueteEventDTO evento) {
        try {
            // 1. Completar datos faltantes (Nombre del repartidor)
            if (evento.getRepartidorNombre() == null || evento.getRepartidorNombre().isEmpty()) {
                UsuarioModel repartidor = obtenerUsuario(evento.getRepartidorId());
                if (repartidor != null) {
                    evento.setRepartidorNombre(repartidor.getNombre());
                } else {
                    throw new RecursoNoEncontradoException(
                            "Repartidor no encontrado con ID: " + evento.getRepartidorId());
                }
            }

            // 2. Obtener clienteId si falta
            if (evento.getClienteId() == null || evento.getClienteId().isEmpty()) {
                PaqueteModel paquete = obtenerPaquete(evento.getPaqueteId());
                if (paquete != null) {
                    evento.setClienteId(paquete.getClienteId());
                } else {
                    throw new RecursoNoEncontradoException("Paquete no encontrado con ID: " + evento.getPaqueteId());
                }
            }

            System.out.println("Notificando pedido asignado - Paquete: " + evento.getPaqueteId() + ", Repartidor: "
                    + evento.getRepartidorNombre());

            // 3. Obtener cliente para su token
            UsuarioModel cliente = obtenerUsuario(evento.getClienteId());

            if (cliente == null) {
                throw new RecursoNoEncontradoException("Cliente no encontrado con ID: " + evento.getClienteId());
            }

            Map<String, String> data = new HashMap<>();
            data.put("tipo", "asignado");
            data.put("paqueteId", evento.getPaqueteId());
            data.put("repartidorId", evento.getRepartidorId());
            data.put("userId", evento.getClienteId());

            String titulo = "👤 Repartidor asignado";
            String mensaje = String.format("%s fue asignado a tu paquete", evento.getRepartidorNombre());

            // Guardar en Firestore (Historial)
            guardarNotificacionEnFirestore(evento.getClienteId(), titulo, mensaje, "asignado", data);

            // Enviar Push si tiene token
            if (cliente.getFcmToken() != null && !cliente.getFcmToken().isEmpty()) {
                fcmService.enviarNotificacion(cliente.getFcmToken(), titulo, mensaje, data);
                System.out.println("Notificación enviada al cliente: " + evento.getClienteId());
            } else {
                System.out.println(
                        "Cliente " + evento.getClienteId() + " no tiene token FCM, solo se guardó en historial");
            }

        } catch (RecursoNoEncontradoException e) {
            throw e; // Re-lanzar para que el controlador la capture
        } catch (Exception e) {
            System.out.println("Error al notificar pedido asignado: " + e.getMessage());
            e.printStackTrace();
            throw new NotificacionException("Error interno al procesar notificación de pedido asignado", e);
        }
    }

    /**
     * CASO 4: Notificar al cliente que su paquete fue entregado
     */
    public void notificarPedidoEntregado(PaqueteEventDTO evento) {
        try {
            // Si falta el clienteId, buscarlo en el paquete
            if (evento.getClienteId() == null) {
                PaqueteModel paquete = obtenerPaquete(evento.getPaqueteId());
                if (paquete != null) {
                    evento.setClienteId(paquete.getClienteId());
                } else {
                    throw new RecursoNoEncontradoException("Paquete no encontrado con ID: " + evento.getPaqueteId());
                }
            }

            System.out.println("Notificando pedido entregado - Paquete: " + evento.getPaqueteId() + ", Cliente: "
                    + evento.getClienteId());

            UsuarioModel cliente = obtenerUsuario(evento.getClienteId());

            if (cliente == null) {
                throw new RecursoNoEncontradoException("Cliente no encontrado con ID: " + evento.getClienteId());
            }

            Map<String, String> data = new HashMap<>();
            data.put("tipo", "entrega");
            data.put("paqueteId", evento.getPaqueteId());
            data.put("userId", evento.getClienteId());

            String titulo = "✅ Paquete entregado";
            String mensaje = "Tu paquete ha sido entregado exitosamente";

            // Guardar en Firestore (Historial)
            guardarNotificacionEnFirestore(evento.getClienteId(), titulo, mensaje, "entrega", data);

            // Enviar Push si tiene token
            if (cliente.getFcmToken() != null && !cliente.getFcmToken().isEmpty()) {
                fcmService.enviarNotificacion(cliente.getFcmToken(), titulo, mensaje, data);
                System.out.println("Notificación enviada al cliente: " + evento.getClienteId());
            } else {
                System.out.println(
                        "Cliente " + evento.getClienteId() + " no tiene token FCM, solo se guardó en historial");
            }

        } catch (RecursoNoEncontradoException e) {
            throw e;
        } catch (Exception e) {
            System.err.println("Error al notificar pedido entregado: " + e.getMessage());
            e.printStackTrace();
            throw new NotificacionException("Error interno al procesar notificación de pedido entregado", e);
        }
    }

    // --- MÉTODOS AUXILIARES DE FIRESTORE ---

    private void guardarNotificacionEnFirestore(String userId, String titulo, String mensaje, String tipo,
            Map<String, String> data) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            String notificacionId = String.valueOf(System.currentTimeMillis());

            Map<String, Object> notificacion = new HashMap<>();
            notificacion.put("id", notificacionId);
            notificacion.put("userId", userId);
            notificacion.put("titulo", titulo);
            notificacion.put("mensaje", mensaje);
            notificacion.put("fecha", new java.util.Date());
            notificacion.put("leida", false);
            notificacion.put("tipo", tipo);
            notificacion.put("data", data);

            db.collection("usuarios")
                    .document(userId)
                    .collection("notificaciones")
                    .document(notificacionId)
                    .set(notificacion);

            System.out.println("Notificación guardada en Firestore para usuario: " + userId);
        } catch (Exception e) {
            System.err.println("Error al guardar notificación en Firestore para usuario: " + userId);
            e.printStackTrace();
        }
    }

    private UsuarioModel obtenerUsuario(String userId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot doc = db.collection("usuarios").document(userId).get().get();
            if (doc.exists()) {
                return doc.toObject(UsuarioModel.class);
            }
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error al obtener usuario " + userId + ": " + e.getMessage());
        }
        return null;
    }

    private PaqueteModel obtenerPaquete(String paqueteId) {
        try {
            Firestore db = FirestoreClient.getFirestore();
            DocumentSnapshot doc = db.collection("paquetes").document(paqueteId).get().get();
            if (doc.exists()) {
                return doc.toObject(PaqueteModel.class);
            }
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error al obtener paquete " + paqueteId + ": " + e.getMessage());
        }
        return null;
    }

    private Map<String, String> obtenerRepartidoresConTokens() {
        Map<String, String> tokens = new HashMap<>();
        try {
            Firestore db = FirestoreClient.getFirestore();
            QuerySnapshot query = db.collection("usuarios")
                    .whereEqualTo("rol", "repartidor")
                    .get().get();

            for (DocumentSnapshot doc : query.getDocuments()) {
                String token = doc.getString("fcmToken");
                if (token != null && !token.isEmpty()) {
                    tokens.put(doc.getId(), token);
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            System.err.println("Error al buscar repartidores: " + e.getMessage());
        }
        return tokens;
    }
}
